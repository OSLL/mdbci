require 'scanf'

require_relative  '../core/out'

class Node
  attr_accessor :config # Name of stand
  attr_accessor :name
  attr_accessor :state
  attr_accessor :provider
  attr_accessor :ip

  def getIp(provider)
    if provider == '(virtualbox)'
      cmd = 'vagrant ssh '+@name+' -c "/sbin/ifconfig eth1 | grep \"inet \" "'
      vagrant_out = `#{cmd}`
      ip = vagrant_out.scanf('inet addr:%s Bcast')
      @ip = ip[0].nil? ? '127.0.0.1' : ip[0]
    elsif provider == '(aws)'
      cmd = 'vagrant ssh '+@name+' -c "curl http://169.254.169.254/latest/meta-data/public-ipv4"'
      vagrant_out = `#{cmd}`
      ip = vagrant_out.scanf('%s')
      @ip = ip.to_s.sub(/#{'Connection'}.+/, 'Connection').tr('[""]', '')
    else
      $out.warning 'WARNING: Unknown machine type!'
    end
    $out.info 'IP:'+@ip
  end

  def initialize(config, initString)
    parts = initString.scanf('%s %s %s')
    if parts.length == 3
      @name = parts[0]
      @state = parts[1]
      @provider = parts[2]
      @config = config
      getIp(@provider)
    else
      $out.error 'ERR: Cannot parse vagrant node description. Has format changed? ['+initString+']'
    end
  end

end
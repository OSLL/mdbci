require 'scanf'

require_relative  '../core/out'

class Node
  attr_accessor :config # Name of stand
  attr_accessor :name
  attr_accessor :state
  attr_accessor :provider
  attr_accessor :ip

  def getIp
    cmd = 'vagrant ssh '+@name+' -c "/sbin/ifconfig eth1 | grep \"inet \" "'
    $out.info cmd
    vagrant_out = `#{cmd}`
    $out.info '>>'+vagrant_out
    ip = vagrant_out.scanf('inet addr:%s Bcast')
    @ip = ip[0].nil? ? '127.0.0.1' : ip[0]
    $out.info 'IP:'+@ip
  end

  def initialize(config, initString)
    parts = initString.scanf('%s %s %s')
    if parts.length == 3
      @name = parts[0]
      @state = parts[1]
      @provider = parts[2]
      @config = config
      getIp
    else
      $out.error 'ERR: Cannot parse vagrant node description. Has format changed? ['+initString+']'
    end
  end

end
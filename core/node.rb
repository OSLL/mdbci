require 'scanf'

require_relative  '../core/out'

class Node
  attr_accessor :config # Name of stand
  attr_accessor :name
  attr_accessor :state
  attr_accessor :provider
  attr_accessor :ip


  # get node platform name
  def getNodePlatform
    cmd = 'vagrant ssh '+@name+' -c "cat /etc/*-release | grep ID"'
    vagrant_out = `#{cmd}`
    platform = vagrant_out.scanf('%s')
    p "get platform = " + platform.to_s
    return platform.to_s.tr('[]','')
  end

  # check if curl installed on AWS node
  def curlCheck
    cmd_curl = 'vagrant ssh '+@name+' -c "which curl"'
    vagrant_out = `#{cmd_curl}`
    curl = vagrant_out.scanf('%s')
    #
    if curl.to_s.tr('[]','') == ''
      $out.out("Curl not found! Trying to install curl...")
      return false
    else
      return true
    end
  end

  # TODO: install curl -- move to recipe: mariadb or separate build|environment
  def installCurl
    # TODO: check box|ami platform
    #platform = getNodePlatform
    p "install platform = " + platform.to_s
    cmd = 'vagrant ssh '+@name+' -c "sudo apt-get install -y curl"'
    vagrant_cmd = `#{cmd}`
    #
    $out.out("Curl installed! Run 'show network <node>' command again!")
  end

  def getIp(provider)
    if provider == '(virtualbox)'
      cmd = 'vagrant ssh '+@name+' -c "/sbin/ifconfig eth1 | grep \"inet \" "'
      vagrant_out = `#{cmd}`
      ip = vagrant_out.scanf('inet addr:%s Bcast')
      @ip = ip[0].nil? ? '127.0.0.1' : ip[0]
    elsif provider == '(aws)'
      if curlCheck
        cmd = 'vagrant ssh '+@name+' -c "curl http://169.254.169.254/latest/meta-data/public-ipv4"'
        vagrant_out = `#{cmd}`
        ip = vagrant_out.scanf('%s')
        @ip = ip.to_s.sub(/#{'Connection'}.+/, 'Connection').tr('[""]', '')
      else
        installCurl
      end
    else
      $out.warning('WARNING: Unknown machine type!')
    end
    if !@ip.to_s.empty?
      $out.info('IP:'+@ip.to_s)
    else
      $out.warning('IP address is not received! Try to repeate command!')
    end
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
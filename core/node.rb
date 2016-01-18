require 'scanf'
require 'yaml'

require_relative  '../core/out'

class Node
  attr_accessor :config # Name of stand
  attr_accessor :name
  attr_accessor :state
  attr_accessor :provider
  attr_accessor :ip

  def initialize(config, initString)
    parts = initString.scanf('%s %s %s')
    if parts.length == 3
      @name = parts[0]
      @state = parts[1]
      @provider = parts[2]
      @config = config
    else
      $out.error 'ERR: Cannot parse vagrant node description. Has format changed? ['+initString+']'
    end
  end

  #
  # Network
  #
  # get node ip address from ifconfig interface
  def getInterfaceBoxIp(node_name, iface, parse_str)
    cmd = 'vagrant ssh '+node_name+' -c "/sbin/ifconfig '+iface+' | grep \"inet \" "'
    vagrant_out = `#{cmd}`
    ip = vagrant_out.scanf(parse_str.to_s)
    $out.info 'Node.GetIp '+cmd
    @ip = ip[0].nil? ? '127.0.0.1' : ip[0]
  end

  def getIp(provider, platform, is_private)
    case provider
      when '(virtualbox)'
        getInterfaceBoxIp(@name, "eth1", "inet addr:%s Bcast")
      when '(libvirt)'
        if platform == "ubuntu" || platform == "debian"
          getInterfaceBoxIp(@name, "eth0", "inet addr:%s  Bcast")
        else
          getInterfaceBoxIp(@name, "eth0", "inet %s  netmask")
        end
      when '(docker)'
        if platform == "ubuntu" || platform == "debian"
          getInterfaceBoxIp(@name, "eth0", "inet addr:%s  Bcast")
        else
          getInterfaceBoxIp(@name, "eth0", "inet %s  netmask")
        end
      when '(aws)'
        if curlCheck
          if is_private
            cmd = 'vagrant ssh '+@name+' -c "'+$session.awsConfig["private_ip_service"]+'"'
          else
            cmd = 'vagrant ssh '+@name+' -c "'+$session.awsConfig["public_ip_service"]+'"'
          end 
          vagrant_out = `#{cmd}`
          ip = vagrant_out.scanf('%s')
          # get ip from command output
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
      $out.warning('IP address is not received!')
    end
  end

  #
  # Install products
  #
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

  # TODO - now only for Debian/Ubuntu
  def installCurl
    cmd = 'vagrant ssh '+@name+' -c "sudo apt-get install -y curl"'
    vagrant_cmd = `#{cmd}`
    #
    if curlCheck
      $out.out("Curl installed! Try to run 'show network' again!")
    else
      $out.error("Curl not installed!")
    end
  end



end

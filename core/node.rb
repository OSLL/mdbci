require 'scanf'
require 'yaml'
require 'ipaddress'

require_relative  '../core/out'

class Node
  attr_accessor :config # Name of stand
  attr_accessor :name
  attr_accessor :state
  attr_accessor :provider
  attr_accessor :ip

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
    exit_code = 1
    cmd = 'vagrant ssh '+@name+' -c "sudo apt-get install -y curl"'
    vagrant_cmd = `#{cmd}`
    exit_code = $?.exitstatus
    #
    if curlCheck
      $out.out("Curl installed! Try to run 'show network' again!")
    else
      $out.error("Curl not installed!")
    end
    return exit_code
  end

  # get node ip address from ifconfig interface
  def getInterfaceBoxIp(node_name, iface)

    exit_code = 1

    cmd = 'vagrant ssh '+node_name+' -c "/sbin/ifconfig '+iface+' | grep \"inet \" "'
    vagrant_out = `#{cmd}`
    exit_code = $?.exitstatus

    # parse ifconfig output
    ip = vagrant_out.scanf("inet %s")
    # del addr: from ip
    ip_addr = ip[0].to_s.sub('addr:','')
    # check ip with a IP RegExp
    IPAddress.valid?(ip_addr.to_s) ? $out.info('Node IP '+ip_addr.to_s+' is valid!') : $out.info('Node IP '+ip_addr.to_s+' is not valid!')
    @ip = ip_addr.nil? ? '127.0.0.1' : ip_addr

    return exit_code
  end

  def getIp(provider, is_private)

    exit_code = 1

    if provider.nil?
      $out.error "Can not identify configuration for provider #{provider.to_s}"
      return 1
    end

    case provider
      when '(virtualbox)'
        exit_code = getInterfaceBoxIp(@name, "eth1")
      when '(libvirt)'
        exit_code = getInterfaceBoxIp(@name, "eth0")
      when '(docker)'
        exit_code = getInterfaceBoxIp(@name, "eth0")
      when '(aws)'
        if curlCheck
          if is_private
            cmd = 'vagrant ssh '+@name+' -c "'+$session.awsConfig["private_ip_service"]+'"'
          else
            cmd = 'vagrant ssh '+@name+' -c "'+$session.awsConfig["public_ip_service"]+'"'
          end
          vagrant_out = `#{cmd}`
          exit_code = $?.exitstatus
          ip = vagrant_out.scanf('%s')
          # get ip from command output
          @ip = ip.to_s.sub(/#{'Connection'}.+/, 'Connection').tr('[""]', '')
        else
          installCurl
        end
      else
        $out.warning('WARNING: Unknown machine type!')
    end

    !@ip.to_s.empty? ? $out.info('IP:'+@ip.to_s) : $out.warning('IP address is not received!')

    if exit_code != 0
      $out.error "vagrant ssh get IP command returned non-zero exit code: (#{$?.exitstatus})"
      exit_code = 1
    end

    return exit_code
  end


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

end

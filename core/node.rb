require 'scanf'
require 'yaml'
require 'ipaddress'
require 'socket'

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
    $out.info('getInterfaceBoxIp attempt')
    vagrant_out = `vagrant ssh-config #{node_name} | grep HostName`.strip
    $out.info(vagrant_out)
    $out.info($?.exitstatus.to_s)
    exit_code = $?.exitstatus
    hostname = vagrant_out.split(/\s+/)[1]
    begin
      @ip = IPSocket.getaddress(hostname)
    rescue
      $out.error("Unable to determine IP address for #{node}")
      return -1
    end
    exit_code
  end

  def getIp(provider, is_private)
    exit_code = 1
    if provider.nil?
      raise $out.error "Can not identify configuration for provider #{provider.to_s}"
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
          remote_command = if is_private
                             'curl http://169.254.169.254/latest/meta-data/local-ipv4'
                           else
                             'curl http://169.254.169.254/latest/meta-data/public-ipv4'
                           end
          vagrant_out = `vagrant ssh #{@name} -c '#{remote_command}'`
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
      raise $out.error "vagrant ssh get IP command returned non-zero exit code: (#{$?.exitstatus})"
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

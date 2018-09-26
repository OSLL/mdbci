require 'scanf'
require 'yaml'
require 'ipaddress'
require 'socket'
require_relative 'services/shell_commands'
require_relative 'out'

class Node
  attr_accessor :config # Name of stand
  attr_accessor :name
  attr_accessor :state
  attr_accessor :provider
  attr_accessor :ip

  include ShellCommands

  def initialize(config, init_string)
    @ui = $out
    parts = init_string.scanf('%s %s %s')
    if parts.length == 3
      @name = parts[0]
      @state = parts[1]
      @provider = parts[2]
      @config = config
    else
      @ui.error("ERR: Cannot parse vagrant node description. Has format changed? [#{init_string}]")
    end
  end

  def curl_check
    vagrant_out = run_command("vagrant ssh #{@name} -c 'which curl'")[:output]
    curl = vagrant_out.scanf('%s')
    if curl.to_s.tr('[]', '') == ''
      @ui.out('Curl not found! Trying to install curl...')
      return false
    end
    true
  end

  # TODO - now only for Debian/Ubuntu
  def install_curl
    result = run_command("vagrant ssh #{@name} -c 'sudo apt-get install -y curl'")
    if curl_check
      @ui.out('Curl installed! Try to run "show network" again!')
    else
      @ui.error('Curl not installed!')
    end
    result[:value].exitstatus
  end

  # get node ip address from ifconfig interface
  def get_interface_box_ip(node_name, iface)
    @ui.info('getInterfaceBoxIp attempt')
    result = run_command("vagrant ssh-config #{node_name} | grep HostName")
    vagrant_out = result[:output].strip
    exit_code = result[:value].exitstatus
    @ui.info(vagrant_out)
    @ui.info(exit_code)
    hostname = vagrant_out.split(/\s+/)[1]
    begin
      @ip = IPSocket.getaddress(hostname)
    rescue
      @ui.error("Unable to determine IP address for #{node}")
      return -1
    end
    exit_code
  end

  def get_ip(provider, is_private)
    exit_code = 1
    if provider.nil?
      raise @ui.error "Can not identify configuration for provider #{provider}"
    end
    case provider
    when '(virtualbox)'
      exit_code = get_interface_box_ip(@name, "eth1")
    when '(libvirt)'
      exit_code = get_interface_box_ip(@name, "eth0")
    when '(docker)'
      exit_code = get_interface_box_ip(@name, "eth0")
    when '(aws)'
      if curl_check
        remote_command = if is_private
                           'curl http://169.254.169.254/latest/meta-data/local-ipv4'
                         else
                           'curl http://169.254.169.254/latest/meta-data/public-ipv4'
                         end
        result = run_command("vagrant ssh #{@name} -c '#{remote_command}'")
        vagrant_out = result[:output]
        exit_code = result[:value].exitstatus
        ip = vagrant_out.scanf('%s')
        # get ip from command output
        @ip = ip.to_s.sub(/#{'Connection'}.+/, 'Connection').tr('[""]', '')
      else
        install_curl
      end
    else
      @ui.warning('WARNING: Unknown machine type!')
    end
    !@ip.to_s.empty? ? @ui.info('IP:' + @ip.to_s) : @ui.warning('IP address is not received!')
    if exit_code != 0
      raise @ui.error("vagrant ssh get IP command returned non-zero exit code: #{exit_code}")
    end
    exit_code
  end
end

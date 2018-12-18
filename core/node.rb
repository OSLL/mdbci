# frozen_string_literal: true

require 'ipaddress'
require 'socket'
require_relative 'services/shell_commands'
require_relative 'out'

# Represents single node from confugiration file
class Node
  include ShellCommands

  AWS_METADATA_URL = 'http://169.254.169.254/latest/meta-data'

  attr_accessor :config
  attr_accessor :name
  attr_accessor :provider
  attr_accessor :ip

  def initialize(config, node_name)
    @ui = $out
    @config = config
    @name = node_name
    @provider = @config.provider
  end

  # Returns local node ip address from ifconfig interface
  #
  # @return [String] Node IP address
  def get_interface_box_ip
    result = run_command("vagrant ssh-config #{@node_name} | grep HostName")
    raise "vagrant ssh-config #{@node_name} exited with non 0 exit code" unless result[:value].success?
    vagrant_out = result[:output].strip
    hostname = vagrant_out.split(/\s+/)[1]
    IPSocket.getaddress(hostname)
  end

  # Returns AWS node ip address
  #
  # @return [String] Node IP address
  def get_aws_node_ip(name, is_private)
    remote_command = if is_private
                       "curl #{AWS_METADATA_URL}/local-ipv4"
                     else
                       "curl #{AWS_METADATA_URL}/public-ipv4"
                     end
    result = run_command("vagrant ssh #{name} -c '#{remote_command}'")
    raise "#{remote_command} exited with non 0 exit code" unless result[:value].success?
    result[:output].strip
  end

  def get_ip(_provider, is_private)
    @ip = if %w[virtualbox libvirt docker].include?(@provider)
            get_interface_box_ip(@name)
          elsif @provider == '(aws)'
            get_aws_node_ip(@name, is_private)
          else
            raise 'Unknown box provider!'
          end
  rescue SocketError, RuntimeError => e
    @ui.error('IP address is not received!')
    @ui.error(e.message)
    raise
  else
    @ui.info("IP: #{@ip}")
    @ip
  end
end

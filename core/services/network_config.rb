# frozen_string_literal: true

require_relative '../node'
require_relative 'shell_commands'

# Network configurator for vagrant nodes
class NetworkConfig
  include ShellCommands

  def initialize(config, logger, nodes_to_configure = config.node_names)
    @config = config
    @ui = logger
    @nodes = {}
    @config.node_names.each do |name|
      next unless nodes_to_configure.include?(name)
      begin
        @nodes[name] = Node.new(@config, name)
      rescue RuntimeError
        @ui.info("Node #{name} is not running. Skipping")
      end
    end
  end

  # Get node public IP
  #
  # @param node_name [String] name of the node
  # return [String] public ipv4 address
  def get_network(node_name)
    @nodes[node_name].get_ip(false)
  end

  # Path to node private key file
  #
  # @param node_name [String] name of the node
  # return [String] path to private_key
  def get_keyfile(node_name)
    @nodes[node_name].identity_file
  end

  # Get node private IP
  #
  # @param node_name [String] name of the node
  # return [String] private ipv4 address
  def get_private_ip(node_name)
    @nodes[node_name].get_ip(true)
  end

  def get_whoami(node_name)
    @nodes[node_name].user
  end

  # Get information about the network configuration of the particular node
  #
  # @param node [String] name of the node to get information about
  # @param configuration [Configuration] mdbci configuration
  # @param session [Session] session object that allows to run commands on remote machine
  # @return [Hash] node network configuration
  def get_node_network_config(node)
    {
      'network' => get_network(node),
      'keyfile' => get_keyfile(node),
      'private_ip' => get_private_ip(node),
      'whoami' => get_whoami(node),
      'hostname' => @config.template[node]['hostname']
    }
  end

  def self.get_node_network_config(config, logger, node)
    NetworkConfig.new(config, logger, [node]).get_node_network_config(node)
  end
end

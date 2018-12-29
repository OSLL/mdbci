# frozen_string_literal: true

require_relative '../node'
require_relative 'shell_commands'

# Network configurator for vagrant nodes
class NetworkConfig
  include ShellCommands

  def initialize(config, logger)
    @config = config
    @ui = logger
    @nodes = {}
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
  def [](node)
    {
      'network' => get_network(node),
      'keyfile' => get_keyfile(node),
      'private_ip' => get_private_ip(node),
      'whoami' => get_whoami(node),
      'hostname' => @config.template[node]['hostname']
    }
  end

  # Adds configuration for a list of nodes.
  # Names not in the configuration file will be ignored
  #
  # @param [Array<String>] names of node to add
  def add_nodes(node_names)
    node_names.each do |name|
      @nodes[name] = Node.new(@config, name) if @config.node_names.include?(name)
    end
  end

  # Iterates over hash with nodes calling passed block for each node
  def each_pair
    @nodes.each_pair do |name, config|
      yield(name, self[name])
    end
  end
end

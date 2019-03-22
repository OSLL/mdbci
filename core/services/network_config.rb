# frozen_string_literal: true

require_relative '../node'

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

  # Get uername for given node
  #
  # @param node_name [String] name of the node
  # return [String] node user name
  def get_whoami(node_name)
    @nodes[node_name].user
  end

  # Get information about the network configuration of the particular node
  #
  # @param node [String] name of the node to get information about
  # @return [Hash] node network configuration
  def [](node)
    {
      'network' => get_network(node),
      'keyfile' => get_keyfile(node),
      'private_ip' => get_private_ip(node),
      'whoami' => get_whoami(node),
      'hostname' => @config.node_configurations[node]['hostname']
    }
  end

  # Adds configuration for a list of nodes.
  # Names not in the configuration file will be ignored
  #
  # @param node_names [Array<String>] of node to add
  def add_nodes(node_names)
    node_names.each do |name|
      @nodes[name] = Node.new(@config, name) if @config.node_names.include?(name)
    end
  end

  # Iterates over hash with nodes calling passed block for each node
  def each_pair
    @nodes.each_key do |name|
      yield(name, self[name])
    end
  end

  # Get a list of labels that have all the machines running currently
  #
  # @return [Array<String>] the list of labels
  def active_labels
    @config.nodes_by_label.select do |_, nodes|
      nodes.all? { |node| @nodes.key?(node) }
    end.keys
  end
end

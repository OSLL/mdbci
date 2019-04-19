# frozen_string_literal: true

require_relative '../models/network_config_file'
require_relative '../services/machine_configurator'
require 'net/ssh'

# This class loads ssh keys to configuration or selected nodes.
class ConfigureNetworkCommand
  # Create the command instance.
  # @param args [String] string of arguments splits / for the current command.
  # @param keyFile [String] path for ssh key on local machine
  # @param labels [String] label of nodes for the current command
  # @param out [Out] the object that should be used to log information.
  def initialize(args, keyfile, labels, out)
    raise 'Configuration name is required' if args.nil?

    @args = args.split('/')
    raise "Directory with nodes does not exists: #{@args[0]}" unless Dir.exist? @args[0]

    @keyfile = keyfile
    @labels = labels
    @mc = MachineConfigurator.new(out)
    @config = Configuration.new(@args[0])
  end

  # This method is called whenever the command is executed
  def execute
    if @args[1].nil? # No node argument, copy keys to all nodes
      if @labels.nil?
        public_keys_to_configuration
      else
        public_keys_to_nodes_with_label
      end
    else
      public_keys_to_node
    end
  end

  private

  # copy ssh keys to config
  def public_keys_to_configuration
    exit_code = 0
    nodes = @config.node_configurations
    raise "No aws, vbox, libvirt, docker nodes found in #{@args[0]}" if nodes.empty?

    nodes.each do |node|
      machine = parse_node(node)
      code = upload_ssh_file(machine)
      exit_code = 1 if code == 1
    end
    exit_code
  end

  # copy ssh keys to nodes with select label
  def public_keys_to_nodes_with_label
    exit_code = 0
    count = 0
    nodes = @config.node_configurations
    raise "No aws, vbox, libvirt, docker nodes found in #{@args[0]}" if nodes.empty?

    nodes.each do |node|
      next if node[1]['labels'].nil?

      next if node[1]['labels'].include? @labels

      count = 1
      machine = parse_node(node)
      code = upload_ssh_file(machine)
      exit_code = 1 if code == 1
    end
    print "No such node with label #{@label}\n" if count.zero?

    exit_code
  end

  # copy ssh keys to select node
  def public_keys_to_node
    node = @config.node_configurations.find { |nodeinfo| nodeinfo[1]['hostname'] == @args[1] }
    raise "No such node with name #{@args[1]} in #{@args[0]}\n" if node.nil?

    machine = parse_node(node)
    upload_ssh_file(machine)
  end

  # Connect to the specified machine and upload ssh keyfile
  # @param machine [Hash] information about machine to connect
  def upload_ssh_file(machine)
    exit_code = 0
    options = Net::SSH.configuration_for(machine['network'], true)
    options[:auth_methods] = %w[publickey none]
    options[:verify_host_key] = false
    options[:keys] = [machine['keyfile']]
    begin
      Net::SSH.start(machine['network'], machine['whoami'], options) do |ssh|
        @mc.upload_file(ssh, @keyfile, '.ssh/authorized_keys', false)
      end
    rescue StandardError
      print "Could not connaction to machine with name #{machine['name']}\n"
      exit_code = 1
    end
    exit_code
  end

  # Parse information about machine
  # @param node [Node] node object
  def parse_node(node)
    raise "No such node with name #{args[1]} in #{args[0]}" if node.nil?

    config = NetworkConfigFile.new(Dir.pwd + '/' + @args[0] + '_network_config')
    { 'whoami' => config.configs[node[1]['hostname']]['whoami'],
      'network' => config.configs[node[1]['hostname']]['network'],
      'keyfile' => config.configs[node[1]['hostname']]['keyfile'],
      'name' => node[1]['hostname'] }
  end
end

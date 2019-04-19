require_relative '../models/network_config_file'
require_relative '../services/machine_configurator'
require_relative '../network'
require 'net/ssh'

class ConfigureNetworkCommand

  def initialize(args, keyFile, labels, out)
    raise 'Configuration name is required' if args.nil?
    @args = args.split('/')
    raise "Directory with nodes does not exists: #{@args[0]}" unless Dir.exists? @args[0]
    @keyFile = keyFile
    @labels = labels
    @out = out
    @mc = MachineConfigurator.new(@out)
    @config = Configuration.new(@args[0])
  end
  
  # copy ssh keys to config/node
  def execute
    if @args[1].nil? # No node argument, copy keys to all nodes
      if @labels.nil?
        public_keys_for_configuration
      else
        public_keys_for_nodes_with_label
      end
    else
      public_keys_for_node
    end
  end
  
  private
  
  # copy ssh keys to config
  def public_keys_for_configuration
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
  def public_keys_for_nodes_with_label
    exit_code = 0
    count = 0
    nodes = @config.node_configurations
    raise "No aws, vbox, libvirt, docker nodes found in #{@args[0]}" if nodes.empty?
    nodes.each do |node|
      unless node[1]["labels"].nil?
        if node[1]["labels"].include? @labels
          count = 1
          machine = parse_node(node)
          code = upload_ssh_file(machine)
          exit_code = 1 if code == 1
        end
      end
    end
    print "No such node with label #{@label}\n" if count == 0
    exit_code
  end
  
  # copy ssh keys to select node
  def public_keys_for_node
    exit_code = 0
    node = @config.node_configurations.find{ |node| node[1]["hostname"] == @args[1]}
    unless node.nil?
      machine = parse_node(node)
      exit_code = upload_ssh_file(machine)
    else
      raise "No such node with name #{@args[1]} in #{@args[0]}\n"
    end
    exit_code
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
        @mc.upload_file(ssh, @keyFile, ".ssh/authorized_keys", false)
      end
    rescue
      print "Could not connaction to machine with name #{machine['name']}\n"
      exit_code = 1
    end
    exit_code
  end

  # Parse information about machine
  # @param node [Node] node object
  def parse_node(node)
    if node.nil?
      raise "No such node with name #{args[1]} in #{args[0]}"
    end
    config = NetworkConfigFile.new(Dir.pwd + '/' + @args[0] + '_network_config')
    {"whoami" => config.configs[node[1]["hostname"]]["whoami"],
     "network" => config.configs[node[1]["hostname"]]["network"],
     "keyfile" => config.configs[node[1]["hostname"]]["keyfile"],
     "name" => node[1]["hostname"]}
  end
end

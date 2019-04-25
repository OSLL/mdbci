# frozen_string_literal: true

require_relative '../models/network_config_file'
require_relative '../services/machine_configurator'
require 'net/ssh'

# This class loads ssh keys to configuration or selected nodes.
class ConfigureNetworkCommand < BaseCommand
  # Create the command instance.
  # @param args [String] string of arguments splits / for the current command.
  # @param keyFile [String] path for ssh key on local machine
  # @param labels [String] label of nodes for the current command
  # @param out [Out] the object that should be used to log information.
  def initialize(args, env, out)
    raise 'Configuration name is required' if args.nil?

    @config = Configuration.new(args, env.labels)
    @keyfile = env.keyFile
    @out = out
    @configfile = NetworkConfigFile.new(@config.network_settings_file)
  end

  # This method is called whenever the command is executed
  def execute
    public_keys
  end

  private

  # copy ssh keys to config
  def public_keys
    exit_code = 0
    nodes = @config.node_configurations
    raise "No aws, vbox, libvirt, docker nodes found in #{@args[0]}" if nodes.empty?

    nodes.each do |node|
      next unless @config.node_names.include? node[1]['hostname']

      machine = parse_node(node)
      code = upload_ssh_file(machine)
      exit_code = 1 if code == 1
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
        ssh.scp.upload!(@keyfile, '.ssh/authorized_keys', recursive: false)
      end
    rescue StandardError
      @out.info "Could not connaction to machine with name #{machine['name']}\n"
      exit_code = 1
    end
    exit_code
  end

  # Parse information about machine
  # @param node [Node] node object
  def parse_node(node)
    raise "No such node with name #{node[1]['hostname']} in #{args[0]}" if node.nil?

    { 'whoami' => @configfile.configs[node[1]['hostname']]['whoami'],
      'network' => @configfile.configs[node[1]['hostname']]['network'],
      'keyfile' => @configfile.configs[node[1]['hostname']]['keyfile'],
      'name' => node[1]['hostname'] }
  end
end

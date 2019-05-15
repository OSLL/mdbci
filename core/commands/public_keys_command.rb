# frozen_string_literal: true

require_relative '../models/network_settings'
require_relative '../services/machine_configurator'
require 'net/ssh'

# This class loads ssh keys to configuration or selected nodes.
class PublicKeysCommand < BaseCommand
  # This method is called whenever the command is executed
  def execute
    exit_code = SUCCESS_RESULT
    if @env.show_help
      show_help
      return SUCCESS_RESULT
    end
    return ARGUMENT_ERROR_RESULT unless init == SUCCESS_RESULT

    @mdbci_config.node_names.each do |node_name|
      @ui.info("Putting the key file to node '#{node_name}'")
      ssh_connection_parameters = setup_ssh_key(node_name)
      result = configure_server_ssh_key(ssh_connection_parameters)
      exit_code = ERROR_RESULT if result == ERROR_RESULT
    end
    exit_code
  end

  def show_help
    info = <<-HELP
 'public_keys' command allows you to copy the ssh key for the entire configuration.
 You must specify the location of the ssh key using --key:
 mdbci public_keys --key location/keyfile.file config

 You can copy the ssh key for a specific node by specifying it with:
 mdbci public_keys --key location/keyfile.file config/node

 You can copy the ssh key for nodes that correspond to the selected tags:
 mdbci public_keys --key location/keyfile.file --labels label config
    HELP
    @ui.info(info)
  end

  private

  # Initializes the command variable.
  def init
    if @args.first.nil?
      @ui.error('Please specify the configuration')
      return ARGUMENT_ERROR_RESULT
    end

    @mdbci_config = Configuration.new(@args.first, @env.labels)
    @keyfile = @env.keyFile.to_s
    unless File.exist?(@keyfile)
      @ui.error('Please specify the key file to put to nodes')
      return ARGUMENT_ERROR_RESULT
    end
    begin
      @network_config = NetworkSettings.from_file(@mdbci_config.network_settings_file)
    rescue StandardError
      @ui.error('Network settings file is not found for the configuration')
      return ARGUMENT_ERROR_RESULT
    end
    SUCCESS_RESULT
  end

  # Connect and add ssh key on server
  # @param machine [Hash] information about machine to connect
  def configure_server_ssh_key(machine)
    exit_code = SUCCESS_RESULT
    options = Net::SSH.configuration_for(machine['network'], true)
    options[:auth_methods] = %w[publickey none]
    options[:verify_host_key] = false
    options[:keys] = [machine['keyfile']]
    begin
      Net::SSH.start(machine['network'], machine['whoami'], options) do |ssh|
        add_key(ssh)
      end
    rescue StandardError
      @ui.error("Could not initiate connection to the node '#{machine['name']}'")
      exit_code = ERROR_RESULT
    end
    exit_code
  end

  # Adds ssh key to the specified server
  # param ssh [Connection] ssh connection to use
  def add_key(ssh)
    output = ssh.exec!('cat ~/.ssh/authorized_keys')
    key_file_content = File.read(@keyfile)
    ssh.exec!('mkdir ~/.ssh')
    ssh.exec!("echo '#{key_file_content}' >> ~/.ssh/authorized_keys") unless output.include? key_file_content
  end

  # Setup ssh key data
  # @param node_name [String] name of the node
  def setup_ssh_key(node_name)
    network_settings = @network_config.node_settings(node_name)
    { 'whoami' => network_settings['whoami'],
      'network' => network_settings['network'],
      'keyfile' => network_settings['keyfile'],
      'name' => node_name }
  end
end

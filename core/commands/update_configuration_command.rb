# frozen_string_literal: true

require 'fileutils'
require 'yaml'
require_relative 'base_command'
require_relative '../models/configuration'

# Update the configuration file of the MaxScale and restart the service
class UpdateConfigurationCommand < BaseCommand
  def self.synopsis
    'Update the service configuration file and restart the service.'
  end

  def show_help
    info = <<~HELP

      Command allows to update the configuration of the MaxScale and restart the service.
      Currently the MDBCI supports only the Docker configuration.

      When invoking the command you must provide the name of the node that must be updated.
      If you specify several nodes, then all the nodes will be updated.

      ./mdbci update-configuration/node --configuration-file file.cfg

      The command will wait for the new service to start. The network information file will be updated.
    HELP
    @ui.info(info)
  end

  def execute
    if @env.show_help
      show_help
      return SUCCESS_RESULT
    end

    result = setup_command
    return result unless result == SUCCESS_RESULT

    result = update_master_docker_configuration
    return result unless result == SUCCESS_RESULT

    result = update_partial_configuration
    return result unless result == SUCCESS_RESULT

    SUCCESS_RESULT
  end

  # rubocop:disable Metrics/MethodLength
  def setup_command
    if @args.empty?
      @ui.error('Please specify the configuration and node that should be updated')
      return ERROR_RESULT
    end

    begin
      @configuration = Configuration.new(@args.first, @env.labels)
    rescue ArgumentError => error
      @ui.error('Unable to detect the configuration')
      @ui.error(error.message)
      return ERROR_RESULT
    end

    if @configuration.provider != 'docker'
      @ui.error('The command only supports the Docker configuration')
      return ERROR_RESULT
    end

    @config_file = @env.configuration_file
    if @config_file.nil? || !File.exist?(@config_file)
      @ui.error('Please specify path to the new configuration file for the service')
      return ERROR_RESULT
    end

    @docker_config = @configuration.docker_configuration
    SUCCESS_RESULT
  end
  # rubocop:enable Metrics/MethodLength

  def update_master_docker_configuration
    @configuration.node_names.each do |node|
      update_node_configuration(node)
    end
    File.write(@configuration.docker_configuration_path, YAML.dump(@docker_config))
    SUCCESS_RESULT
  end

  # Update the configuration of the specified node
  # @param node [String] name of the node to update
  def update_node_configuration(node)
    node_config = @docker_config['services'][node]

    current_config_version = node_config['deploy']['labels']['org.mariadb.node.config_version']
    current_config_label = "#{node}_config_#{current_config_version}"
    @docker_config['configs'].delete(current_config_label)

    config_version = current_config_version + 1
    config_label = "#{node}_config_#{config_version}"
    config_file = copy_configuration_file(node, config_version)
    @docker_config['configs'][config_label] = { 'file' => config_file }
    node_config['deploy']['labels']['org.mariadb.node.config_version'] = config_version
    update_node_configuration_link(node, current_config_label, config_label)
  end

  def update_node_configuration_link(node, current_config_label, config_label)
    node_config = @docker_config['services'][node]


    node_config['configs'].each do |config|
      next unless config['source'] == current_config_label

      config['source'] = config_label
    end

  end

  # Copy the passed configuration file as the configuration for the specified node
  # @param node [String] name of the node
  # @param version [Number] the version of the configuration file
  def copy_configuration_file(node, version)
    configuration_directory = File.join(@configuration.path, 'configs', node)
    FileUtils.mkdir_p(configuration_directory)
    config_file_name = "#{node}_config_#{version}.cnf"
    configuration_file = File.join(configuration_directory, config_file_name)
    FileUtils.cp(@config_file, configuration_file)
    configuration_file
  end

  # Update the partial configuration according to the existing configuration.
  # If the partial configuration is present, then update the Docker Stack
  def update_partial_configuration
    partial_config_path = @configuration.docker_partial_configuration
    return SUCCESS_RESULT unless File.exist?(partial_config_path)

    partial_config = YAML.load_file(partial_config_path)
    required_service_names = partial_config['services'].keys

    new_partial_config = Marshal.load(Marshal.dump(@docker_config))
    new_partial_config['services'].keep_if { |service_name, _| required_service_names.include?(service_name) }
    File.write(partial_config_path, YAML.dump(new_partial_config))
    SUCCESS_RESULT
  end
end

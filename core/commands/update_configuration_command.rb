# frozen_string_literal: true

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
    SUCCESS_RESULT
  end
  # rubocop:enable Metrics/MethodLength
end

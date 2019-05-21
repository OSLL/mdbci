# frozen_string_literal: true

require_relative 'base_command'

# Update the configuration file of the MaxScale and restart the service
class UpdateConfigurationCommand < BaseCommand
  def self.synopsis
    'Setup environment as specified in the configuration.'
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
    SUCCESS_RESULT
  end
end

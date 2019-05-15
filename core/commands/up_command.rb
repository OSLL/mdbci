# frozen_string_literal: true

require_relative 'base_command'
require_relative 'partials/docker_swarm_configurator'
require_relative 'partials/vagrant_configurator'
require_relative '../models/configuration'

# The command sets up the environment specified in the configuration file.
class UpCommand < BaseCommand
  def self.synopsis
    'Setup environment as specified in the configuration.'
  end

  # rubocop:disable Metrics/MethodLength
  def show_help
    info = <<-HELP
'up' starts virtual machines in the specified configuration.

mdbci up config - configure all VMs in the specified configuration.

mdbci up config/node - configure the specified node from the configuration.

OPTIONS:
  --attempts [number]:
Specifies the number of times VM will be destroyed during the provisioning.
  --threads [number]:
Specifies the number of threads for parallel configuration of virtual machines.
  --recreate:
Specifies that existing VMs must be destroyed before the configuration of all target VMs.
  -l, --labels [string]:
Specifies the list of desired labels. It allows to filter VMs based on the label presence.
If any of the labels passed to the command match any label in the machine description,
then this machine will be brought up and configured according to its configuration.
Labels should be separated with commas and should not contain any whitespaces.
    HELP
    @ui.info(info)
  end
  # rubocop:enable Metrics/MethodLength

  # Checks that all required parameters are passed to the command
  # and set them as instance variables.
  #
  # @raise [ArgumentError] if unable to parse arguments.
  def setup_command
    if @args.empty? || @args.first.nil?
      raise ArgumentError, 'You must specify path to the mdbci configuration as a parameter.'
    end

    @specification = @args.first
    @config = Configuration.new(@specification, @env.labels)
  end

  def bing_up_nodes
    if @config.provider == 'docker'
      configurator = DockerSwarmConfigurator.new(@config, @env, @ui)
      configurator.configure
    else
      configurator = VagrantConfigurator.new(@specification, @config, @env, @ui)
      configurator.up
    end
  end

  def execute
    if @env.show_help
      show_help
      return SUCCESS_RESULT
    end
    begin
      setup_command
    rescue ArgumentError => error
      @ui.error(error.message)
      @ui.error(error.backtrace.join("\n"))
      return ARGUMENT_ERROR_RESULT
    end
    bing_up_nodes
  end
end

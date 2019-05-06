# frozen_string_literal: true

require_relative '../../services/shell_commands'
require_relative '../../models/return_codes'

# The configurator that is able to bring up the Docker swarm cluster
class DockerSwarmConfigurator
  include ReturnCodes
  include ShellCommands

  def initialize(config, env, logger)
    @config = config
    @env = env
    @ui = logger
  end

  def configure
    @ui.info('Bringing up docker nodes')
    return SUCCESS_RESULT unless @config.docker_configuration?

    extract_node_configuration
    if @configuration['services'].empty?
      @ui.info('No Docker services are configured to be brought up')
      return SUCCESS_RESULT
    end
    bring_up_nodes
    SUCCESS_RESULT
  end

  # Extract only the required node configuration from the whole configuration
  # @return [Hash] the Swarm configuration that should be brought up
  def extract_node_configuration
    @ui.info('Selecting Docker Swarm services to be brought up')
    node_names = @config.node_names
    @configuration = @config.docker_configuration
    @configuration['services'].select! do |service_name, _|
      node_names.include?(service_name)
    end

  end

  def bring_up_nodes
    config_file = @config.docker_partial_configuration
    File.write(config_file, YAML.dump(@configuration))
    result = run_command("docker stack deploy -c #{config_file} #{@config.name}")
    unless result[:value].success?
      @ui.error('Unable ')
    end

  end
end

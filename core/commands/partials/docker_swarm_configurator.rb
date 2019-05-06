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
    SUCCESS_RESULT
  end
end

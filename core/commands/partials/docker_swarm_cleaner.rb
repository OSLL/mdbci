# frozen_string_literal: true

require_relative '../../services/shell_commands'

# Docker Swarm stack removal utility
class DockerSwarmCleaner
  include ShellCommands

  def initialize(env, logger)
    @env = env
    @ui = logger
  end

  # Method removes the whole stack
  def destroy_stack(configuration)
    stack_name = configuration.name
    result = run_command_and_log("docker stack rm #{stack_name}")
    @ui.error("Unable to remove the docker swarm stack #{stack_name}") unless result[:value].success?
  end
end

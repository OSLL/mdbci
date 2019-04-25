# frozen_string_literal: true

# The class generates the MDBCI configuration for the use in pair with Docker backend
class DockerConfigurationGenerator
  def initialize(configuration_path, template_file, template, env, logger)
    @template_file = template_file
    @configuration_path = configuration_path
    @template = template
    @env = env
    @ui = logger
  end

  def generate_config

  end
end

# frozen_string_literal: true

require 'fileutils'
require_relative '../models/return_codes'

# The class generates the MDBCI configuration for the use in pair with Docker backend
class DockerConfigurationGenerator
  include ReturnCodes

  def initialize(configuration_path, template_file, template, env, logger)
    @template_file = template_file
    @configuration_path = configuration_path
    @template = template
    @env = env
    @ui = logger
  end

  def generate_config
    crate_configuration_directory
  end

  def crate_configuration_directory
    @ui.info("Creating configuration directory '#{@configuration_path}'")
    FileUtils.mkdir_p("")
    SUCCESS_RESULT
  rescue SystemCallError => error
    @ui.error("Unable to create configuration directory '#{@configuration_path}'.")
    @ui.error("Error message: #{error.message}")
    ERROR_RESULT
  end
end

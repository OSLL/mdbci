# frozen_string_literal: true

require_relative 'base_command'
require_relative '../services/vagrant_configuration_generator'
require_relative '../services/docker_configuration_generator'
require_relative '../models/configuration_template'

# Command acs as the gatekeeper for two generators: Vagrant-based configurator
# and Docker-based configurator
class GenerateCommand < BaseCommand
  def self.synopsis
    'Generate a configuration based on the template.'
  end

  def execute
    check_result = setup_command
    return check_result unless check_result == SUCCESS_RESULT

    if @template.template_type == :vagrant
      generator = VagrantConfigurationGenerator.new(@args, @env, @ui)
      generator.execute(@args.first, @env.override)
    else
      generator = DockerConfigurationGenerator.new(@configuration_path, @template_file, @template, @env, @ui)
      generator.generate_config
    end
  end

  private

  # Method checks that all parameters are passed to the command
  def setup_command
    if @args.empty?
      @ui.error('Please specify path to the configuration that should be generated.')
      return ARGUMENT_ERROR_RESULT
    end

    @configuration_path = File.expand_path(@args.first)
    if Dir.exist?(@configuration_path) && !@env.override
      @ui.error("The specified directory '#{@configuration_path}' already exist. Will not continue to generate.")
      return ARGUMENT_ERROR_RESULT
    end

    result = read_template
    return result unless result == SUCCESS_RESULT

    SUCCESS_RESULT
  end

  # Read the template file and notify if file does not exist or incorrect
  def read_template
    @template_file = File.expand_path(@env.template_file)
    begin
      @template = ConfigurationTemplate.new(@template_file)
      SUCCESS_RESULT
    rescue RuntimeError => error
      @ui.error("Unable to read template file. Error: #{error.message}")
      ARGUMENT_ERROR_RESULT
    end
  end
end

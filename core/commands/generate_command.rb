# frozen_string_literal: true

require_relative 'base_command'

# Command acs as the gatekeeper for two generators: Vagrant-based configurator
# and Docker-based configurator
class GenerateCommand < BaseCommand
  def self.synopsis
    'Generate a configuration based on the template.'
  end

  def execute
    check_result = setup_command
    return check_result unless check_result == SUCCESS_RESULT

    if determine_template_type == :vagrant
      command = VagrantConfigurationGenerator.new(@args, @env, @ui)
      command.execute(@args.first, @env.override)
    else
      SUCCESS_RESULT
    end
  end

  private

  # Method checks that all parameters are passed to the command
  def setup_command
    if @args.empty?
      @ui.error('Please specify path to the configuration that should be generated.')
      return ARGUMENT_ERROR_RESULT
    end

    @configuration_directory = File.expand_path(@args.first)
    if Dir.exist?(@configuration_directory) && !@env.override
      @ui.error("The specified directory '#{@configuration_directory}' already exist. Will not continue to generate.")
      return ARGUMENT_ERROR_RESULT
    end

    result = read_template
    return result unless result == SUCCESS_RESULT

    SUCCESS_RESULT
  end

  # Read the template file and notify if file does not exist or incorrect
  def read_template
    template_file = File.expand_path(@env.template_file)
    unless File.exist?(template_file)
      @ui.error("The specified template file '#{template_file}' does not exist. Please specify correct path.")
      return ARGUMENT_ERROR_RESULT
    end

    begin
      instance_config_file = File.read(template_file)
      @template = JSON.parse(instance_config_file)
    rescue IOError, JSON::ParserError => error
      @ui.error("The configuration file '#{template_file}' is not valid. Error: #{error.message}")
      return ARGUMENT_ERROR_RESULT
    end
    SUCCESS_RESULT
  end

  # Method analyses the structure of the template
  # @returns [Symbol] type of the template: vagrant or docker
  def determine_template_type
    node_configurations = @template.select do |_, element|
      element.instance_of?(Hash) &&
        element.key?('box')
    end
    target_boxes = node_configurations.map { |_, node| node['box'] }
    if target_boxes.include?('docker')
      :docker
    else
      :vagrant
    end
  end
end

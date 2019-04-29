# frozen_string_literal: true

require 'forwardable'

# The representation of the template file that provides tools to get information out of it
class ConfigurationTemplate
  attr_reader :template_type
  extend Forwardable
  def_delegator :@node_configurations, :each, :each_node

  def initialize(template_path)
    @template_path = template_path
    @template = read_template_file
    @node_configurations = extract_node_configurations
    @template_type = determine_template_type
  end

  private
  
  # Read the contents of the template file. Raise exceptions if something is missing
  def read_template_file
    unless File.exist?(@template_path)
      raise("The specified template file '#{@template_path}' does not exist. Please specify correct path.")
    end

    begin
      instance_config_file = File.read(@template_path)
      JSON.parse(instance_config_file)
    rescue IOError, JSON::ParserError => error
      raise("The configuration file '#{@template_path}' is not valid. Error: #{error.message}")
    end
  end

  # Filter the node definitions from out of other data
  def extract_node_configurations
    @template.select do |_, element|
      element.instance_of?(Hash) &&
        element.key?('box')
    end
  end

  # Method analyses the structure of the template
  # @returns [Symbol] type of the template: vagrant or docker
  def determine_template_type
    target_boxes = @node_configurations.map { |_, node| node['box'] }
    if target_boxes.include?('docker')
      :docker
    else
      :vagrant
    end
  end
end

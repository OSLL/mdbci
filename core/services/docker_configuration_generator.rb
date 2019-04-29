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
    create_configuration_directory
    copy_configuration_files
  end

  def create_configuration_directory
    @ui.info("Creating configuration directory '#{@configuration_path}'")
    FileUtils.mkdir_p(@configuration_path)
    SUCCESS_RESULT
  rescue SystemCallError => error
    @ui.error("Unable to create configuration directory '#{@configuration_path}'.")
    @ui.error("Error message: #{error.message}")
    ERROR_RESULT
  end

  def copy_configuration_files
    @ui.info('Copying configuration files')
    service_config_path = File.join(@configuration_path, 'configs')
    FileUtils.mkdir_p(service_config_path)
    @template.each_node do |node_name, node|
      next unless node.key?('product')
      cnf_data = node['product'].values_at('cnf_template_path', 'cnf_template')
      if cnf_data.size != 0 || cnf_data.size != 2
        @ui.error("Error in #{node_name} configuration.")
        @ui.error("You must provide both 'cnf_template' and 'cnf_template_path' when configuring products.")
        return ERROR_RESULT
      end
      FileUtils.cp(File.join(*cnf_data), File.join(service_config_path, "#{node_name}.cnf"), verbose: true)
    end
    SUCCESS_RESULT
  rescue SystemCallError => error
    @ui.error("Error while copying configuration files into '#{service_config_path}'")
    @ui.error("Error message: #{error.message}")
    ERROR_RESULT
  end
end

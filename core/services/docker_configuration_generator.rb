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
      @ui.info("Copying configuration file for the node '#{node_name}'")
      result = copy_product_config_file(node, File.join(service_config_path, "#{node_name}.cnf"))
      return result if result != SUCCESS_RESULT
    end
    SUCCESS_RESULT
  rescue SystemCallError => error
    @ui.error("Error while copying configuration files into '#{service_config_path}'")
    @ui.error("Error message: #{error.message}")
    ERROR_RESULT
  end

  def copy_product_config_file(node, result_file)
    unless node.key?('product')
      @ui.error("The node '#{node_name}' does not specify the product to be installed")
      return ERROR_RESULT
    end
    product = node['product']
    if product.key?('cnf_template') && product.key?('cnf_template_path')
      FileUtils.cp(File.join(File.expand_path(product['cnf_template_path'], File.dirname(@template_file)),
                             product['cnf_template']), result_file)
    elsif product.key?('cnf_template')
      FileUtils.cp(File.expand_path(product['cnf_template'], File.dirname(@template_file)), result_file)
    else
      @ui.error("You must provide path to configuration file in 'cnf_template' and 'cnf_template_path'.")
      return ERROR_RESULT
    end
    SUCCESS_RESULT
  end
end

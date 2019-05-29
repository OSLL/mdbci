# frozen_string_literal: true

require 'fileutils'
require 'find'
require 'yaml'
require_relative '../../models/return_codes'

# The class generates the MDBCI configuration for the use in pair with Docker backend
class DockerConfigurationGenerator
  include ReturnCodes

  DEFAULT_DEPLOY_OPTIONS = {
    'mode' => 'global',
    'restart_policy' => {
      'condition' => 'none'
    },
    'resources' => {
      'limits' => {
        'cpus' => '2',
        'memory' => '1024MB'
      }
    }
  }.freeze

  def initialize(configuration_path, template_file, template, env, logger)
    @template_file = template_file
    @configuration_path = configuration_path
    @template = template
    @env = env
    @ui = logger
    @docker_configs = File.join(env.mdbci_dir, 'assets', 'docker-configs')
    @configuration = Hash.new { |hash, key| hash[key] = {} }
    @configuration['version'] = '3.7'
  end

  def generate_config
    result = make_generation_steps
    delete_configuration_directory unless result == SUCCESS_RESULT
    result
  end

  def delete_configuration_directory
    @ui.info('Removing the configuration directory that contains errors')
    FileUtils.rm_rf(@configuration_path)
    @ui.error("Unable to remove the destination directory '#{@configuration_path}'") if Dir.exist?(@configuration_path)
  end

  def make_generation_steps
    result = create_configuration_directory
    return result unless result == SUCCESS_RESULT

    result = setup_nodes_configuration
    return result unless result == SUCCESS_RESULT

    result = generate_full_configuration
    return result unless result == SUCCESS_RESULT

    write_configuration_files
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

  def setup_nodes_configuration
    @ui.info('Copying node configuration files')
    @template.each_node do |node_name, node|
      result = setup_node_configuration(node_name, node)
      return result unless result == SUCCESS_RESULT
    end
    SUCCESS_RESULT
  rescue SystemCallError => error
    @ui.error('Error while copying configuration files')
    @ui.error("Error message: #{error}")
    ERROR_RESULT
  end

  def setup_node_configuration(node_name, node)
    @ui.info("Configuring the node '#{node_name}'")
    unless node.key?('product')
      @ui.error("The node '#{node_name}' does not specify the product to be installed")
      return ERROR_RESULT
    end
    result = setup_docker_product_image(node_name, node['product'])
    return result unless result == SUCCESS_RESULT

    copy_node_config_files(node_name, node['product'])
  end

  ENVIRONMENT_OPTIONS = {
    'mariadb' => {
      'MARIADB_ALLOW_EMPTY_PASSWORD' => 'true'
    }
  }.freeze

  def setup_docker_product_image(node_name, product)
    image = @env.repos.find_repository(product['name'], product, 'docker')
    if image.nil?
      @ui.error("Unable to find Docker-image for the product specified in '#{node_name}'")
      return ERROR_RESULT
    end
    @configuration['services'][node_name] = {
      'image' => image['repo'],
      'deploy' => Marshal.load(Marshal.dump(DEFAULT_DEPLOY_OPTIONS)),
      'configs' => []
    }
    @configuration['services'][node_name]['deploy']['labels'] = {
      'org.mariadb.node.name' => node_name,
      'org.mariadb.node.config_version' => 0
    }
    if ENVIRONMENT_OPTIONS.key?(product['name'])
      @configuration['services'][node_name]['environment'] = ENVIRONMENT_OPTIONS[product['name']]
    end
    SUCCESS_RESULT
  end

  def copy_node_config_files(node_name, product)
    service_config_path = File.join(@configuration_path, 'configs', node_name)
    FileUtils.mkdir_p(service_config_path)
    config_file_path = File.join(service_config_path, "#{node_name}_0.cnf")
    result = copy_product_config_file(node_name, product, config_file_path)
    return result unless result == SUCCESS_RESULT

    init_files_path = File.join(@configuration_path, 'initialization', node_name)
    FileUtils.mkdir_p(init_files_path)
    copy_initialization_files(node_name, product, init_files_path)
  end

  MUST_PROVIDE_CONFIGURATION = %w[mariadb].freeze

  def copy_product_config_file(node_name, product, result_file)
    @ui.info("Copying configuration file for the node '#{node_name}'")
    if product.key?('cnf_template') && product.key?('cnf_template_path')
      FileUtils.cp(File.join(File.expand_path(product['cnf_template_path'], File.dirname(@template_file)),
                             product['cnf_template']), result_file)
    elsif product.key?('cnf_template')
      FileUtils.cp(File.expand_path(product['cnf_template'], File.dirname(@template_file)), result_file)
    else
      return SUCCESS_RESULT unless MUST_PROVIDE_CONFIGURATION.include?(product['name'])

      @ui.error("You must provide path to configuration file in 'cnf_template' and 'cnf_template_path'.")
      return ERROR_RESULT
    end
    save_service_configuration_file(node_name, product, result_file)
  end

  CONFIGURATION_LOCATIONS = {
    'mariadb' => '/etc/mysql/my.cnf',
    'maxscale' => '/etc/maxscale.cnf'
  }.freeze

  def save_service_configuration_file(node_name, product, result_file)
    unless CONFIGURATION_LOCATIONS.key?(product['name'])
      @ui.error("Do not know where the configuration file must be placed for node '#{node_name}'")
      return ERROR_RESULT
    end

    add_service_configuration_file(node_name, result_file, "#{node_name}_config_0",
                                   CONFIGURATION_LOCATIONS[product['name']])
    SUCCESS_RESULT
  end

  INITIALIZATION_LOCATIONS = {
    'mariadb' => '/docker-entrypoint-initdb.d/'
  }.freeze

  def copy_initialization_files(node_name, product, init_files_path)
    @ui.info("Copying initialization files for the node '#{node_name}'")
    init_assets_path = File.join(@docker_configs, product['name'])
    return SUCCESS_RESULT unless File.exist?(init_assets_path)

    Find.find(init_assets_path).with_index do |file, index|
      next unless File.file?(file)

      result_file = File.join(init_files_path, File.basename(file))
      FileUtils.cp(file, result_file)
      unless INITIALIZATION_LOCATIONS.key?(product['name'])
        @ui.error("Do not know how to configure initialization of product #{product['name']}")
        return ERROR_RESULT
      end
      add_service_configuration_file(node_name, result_file, "#{node_name}_#{index}_init",
                                     File.join(INITIALIZATION_LOCATIONS[product['name']], File.basename(file)))
    end
    SUCCESS_RESULT
  end

  def add_service_configuration_file(service_name, file, configuration_key, target_file_name)
    @configuration['configs'][configuration_key] = {
      'file' => file
    }

    @configuration['services'][service_name]['configs'].push(
      'source' => configuration_key,
      'target' => target_file_name
    )
  end

  def generate_full_configuration
    @ui.info('Generating Docker Swarm configuration file')
    configuration_contents = YAML.dump(@configuration)
    configuration_file = File.join(@configuration_path, 'docker-configuration.yaml')
    File.write(configuration_file, configuration_contents)
    SUCCESS_RESULT
  rescue IOError => error
    @ui.error("Unable to write configuration file '#{configuration_file}'.")
    @ui.error("Error message: #{error.message}")
    ERROR_RESULT
  end

  def write_configuration_files
    @ui.info('Placing required configuration files')
    File.write(File.join(@configuration_path, 'provider'), 'docker')
    File.write(File.join(@configuration_path, 'template'), @template_file)
    SUCCESS_RESULT
  rescue IOError => error
    @ui.error('Unable to create the required configuration files.')
    @ui.error("Error message: #{error.message}")
    ERROR_RESULT
  end
end

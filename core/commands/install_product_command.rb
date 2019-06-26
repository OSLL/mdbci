# frozen_string_literal: true

require_relative '../services/machine_configurator'
require_relative '../models/configuration'
require_relative '../services/configuration_generator'

# This class installs the product on selected node
class InstallProduct < BaseCommand
  def self.synopsis
    'Installs the product on selected node.'
  end

  # This method is called whenever the command is executed
  def execute
    if @env.show_help
      show_help
      return SUCCESS_RESULT
    end
    return ARGUMENT_ERROR_RESULT unless init == SUCCESS_RESULT

    if @mdbci_config.node_names.size != 1
      @ui.error('Invalid node specified')
      return ARGUMENT_ERROR_RESULT
    end

    install_product(@mdbci_config.node_names[0])

    SUCCESS_RESULT
  end

  # Print brief instructions on how to use the command
  def show_help
    info = <<~HELP
      'install_product' Install a product onto the configuration node.
      mdbci install_product --product product --version-product version config/node
    HELP
    @ui.info(info)
  end

  private

  # Initializes the command variable
  def init
    if @args.first.nil?
      @ui.error('Please specify the node')
      return ARGUMENT_ERROR_RESULT
    end
    @mdbci_config = Configuration.new(@args.first, @env.labels)
    @network_config = NetworkConfig.new(@mdbci_config, @ui)

    @product = @env.nodeProduct
    @product_version = @env.productVersion

    begin
      @network_settings = NetworkSettings.from_file(@mdbci_config.network_settings_file)
    rescue StandardError
      @ui.error('Network settings file is not found for the configuration')
      return ARGUMENT_ERROR_RESULT
    end
    @machine_configurator = MachineConfigurator.new(@ui)

    SUCCESS_RESULT
  end

  # Install product on server
  # param node_name [String] name of the node
  def install_product(name)
    role_file_path = generate_role_file(name)
    target_path = "roles/#{name}.json"
    role_file_path_config = "#{@mdbci_config.path}/#{name}-config.json"
    target_path_config = "configs/#{name}-config.json"
    extra_files = [[role_file_path, target_path], [role_file_path_config, target_path_config]]
    @network_config.add_nodes([name])
    @machine_configurator.configure(@network_config[name], "#{name}-config.json",
                                    @ui, extra_files)
  end

  # Create a role file to install the product from the chef
  # @param name [String] node name
  def generate_role_file(name)
    node = @mdbci_config.node_configurations[name]
    box = node['box'].to_s
    recipe_name = @env.repos.recipe_name(@product)
    product = node['product']
    role_file_path = "#{@mdbci_config.path}/#{name}.json"
    if product.nil?
      product = { 'name' => @product, 'version' => @product_version.to_s }
    else
      product < { 'name' => @product, 'version' => @product_version.to_s }
    end
    product_config = ConfigurationGenerator.generate_product_config(@env, @product, product, box, nil)
    role_json_file = ConfigurationGenerator.generate_json_format(@env, name, product_config, recipe_name, box)
    IO.write(role_file_path, role_json_file)
    role_file_path
  end
end

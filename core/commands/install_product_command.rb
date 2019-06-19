# frozen_string_literal: true

require_relative '../services/machine_configurator'
require_relative '../../core/models/configuration'
require_relative '../../core/services/configuration_generator'

# This class installs the product on selected node.
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

    machine = setup_ssh_key(@mdbci_config.node_names[0])
    install_product(machine)

    SUCCESS_RESULT
  end

  # Print brief instructions on how to use the command.
  def show_help
    info = <<~HELP
      'install_product' Install a product onto the configuration node.
      mdbci install_product --product product --version-product version config/node
    HELP
    @ui.info(info)
  end

  private

  # Initializes the command variable.
  def init
    if @args.first.nil?
      @ui.error('Please specify the node')
      return ARGUMENT_ERROR_RESULT
    end
    @mdbci_config = Configuration.new(@args.first, @env.labels)

    @product = @env.nodeProduct
    @product_version = @env.productVersion

    begin
      @network_config = NetworkSettings.from_file(@mdbci_config.network_settings_file)
    rescue StandardError
      @ui.error('Network settings file is not found for the configuration')
      return ARGUMENT_ERROR_RESULT
    end
    @machine_configurator = MachineConfigurator.new(@ui)

    SUCCESS_RESULT
  end

  # Setup ssh key data
  # @param node_name [String] name of the node
  def setup_ssh_key(node_name)
    network_settings = @network_config.node_settings(node_name)
    { 'whoami' => network_settings['whoami'],
      'network' => network_settings['network'],
      'keyfile' => network_settings['keyfile'],
      'name' => node_name }
  end

  # Install product on server
  # @param machine [Hash] information about machine to connect
  def install_product(machine)
    role_file_path = generate_role_file(machine['name'])
    target_path = "configs/#{machine['name']}.json"
    @machine_configurator.configure(machine, "#{machine['name']}.json", @ui,
                                    [[role_file_path, target_path]],
                                    '', '14.7.17')
  end

  # Create a role file to install the product from the chef
  # @param name [String] node name
  def generate_role_file(name)
    box = @mdbci_config.node_configurations[name]['box']
    recipe_name = @env.repos.recipe_name(@product)
    product = @mdbci_config.node_configurations[name]['product']
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

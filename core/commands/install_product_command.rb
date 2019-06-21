# frozen_string_literal: true

require_relative '../services/machine_configurator'
require_relative '../../core/models/configuration'
require_relative '../../core/services/configuration_generator'

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

    machine = setup_ssh_key(@mdbci_config.node_names[0])
    install_product(machine)

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

  # Setup ssh key data
  # @param node_name [String] name of the node
  def setup_ssh_key(node_name)
    node_settings = @network_settings.node_settings(node_name)
    { 'whoami' => node_settings['whoami'],
      'network' => node_settings['network'],
      'keyfile' => node_settings['keyfile'],
      'name' => node_name }
  end

  # Install product on server
  # @param machine [Hash] information about machine to connect
  def install_product(machine)
    name = machine['name'].to_s
    role_file_path = generate_role_file(name)
    target_path = "configs/#{name}-config.json"
    @network_config.add_nodes([name])
    @machine_configurator.configure(@network_config[name], "#{name}-config.json",
                                    @ui, [[role_file_path, target_path]])
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


  # Make a hash list of node parameters by a node configuration and
  # information of the box parameters.
  #
  # @param node [Array] information of the node from configuration file
  # @param box_params [Hash] information of the box parameters
  # @return [Hash] list of the node parameters.
  def make_node_params(node, box_params, name)
    p node
    symbolic_box_params = Hash[box_params.map { |k, v| [k.to_sym, v] }]
    {
      name: name.to_s,
      host: node['hostname'].to_s,
      vm_mem: node['memory_size'].nil? ? '1024' : node['memory_size'].to_s,
      vm_cpu: (@env.cpu_count || node['cpu_count'] || '1').to_s
    }.merge(symbolic_box_params)
  end
end

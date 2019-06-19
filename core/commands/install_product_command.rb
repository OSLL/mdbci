# frozen_string_literal: true

require_relative '../services/machine_configurator'
require_relative '../../core/models/configuration'

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
    product_config = generate_product_config(@product, product, box)
    role_json_file = generate_json_format(name, product_config, recipe_name, box)
    IO.write(role_file_path, role_json_file)
    role_file_path
  end

  # Generate a list of role parameters in JSON format
  # @param name [String] node name
  # @param product_config [Hash] list of the product parameters
  # @param recipe_name [String] name of the recipe
  # @param box [String] name of the box
  def generate_json_format(name, product_config, recipe_name, box)
    run_list = ['recipe[mdbci_provision_mark::remove_mark]',
                "recipe[#{recipe_name}]",
                'recipe[mdbci_provision_mark::default]']
    if check_subscription_manager(box)
      run_list.insert(1, 'recipe[subscription-manager]')
      product_config = product_config.merge('subscription-manager': retrieve_subscription_credentials)
    end
    role = { name: name,
             default_attributes: {},
             override_attributes: product_config,
             json_class: 'Chef::Role',
             description: '',
             chef_type: 'role',
             run_list: run_list }
    JSON.pretty_generate(role)
  end

  # Check whether box needs to be subscribed or not
  # @param box [String] name of the box
  def check_subscription_manager(box)
    @env.box_definitions.get_box(box)['configure_subscription_manager'] == 'true'
  end

  # Generate the list of the product parameters
  # @param product_name [String] name of the product for install
  # @param product [Hash] parameters of the product to configure from configuration file
  # @param box [String] name of the box
  def generate_product_config(product_name, product, box)
    repo = @env.repos.find_repository(product_name, product, box)
    raise "Repo for product #{product['name']} #{product['version']} for #{box} not found" if repo.nil?

    config = { 'version': repo['version'], 'repo': repo['repo'], 'repo_key': repo['repo_key'] }
    if !product['cnf_template'].nil? && !product['cnf_template_path'].nil?
      config['cnf_template'] = product['cnf_template']
      config['cnf_template_path'] = product['cnf_template_path']
    end
    repo_file_name = @env.repos.repo_file_name(product_name)
    config['repo_file_name'] = repo_file_name unless repo_file_name.nil?
    config['node_name'] = product['node_name'] unless product['node_name'].nil?
    attribute_name = @env.repos.attribute_name(product_name)
    { "#{attribute_name}": config }
  end
end

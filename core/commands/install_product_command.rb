# frozen_string_literal: true

require_relative '../services/machine_configurator'

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
  mdbci install_product config/node --product product --version-product version
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
    solo_config = "#{machine['name']}-config.json"
    role_file = "#{@mdbci_config.path}/#{machine['name']}.json"
    generate_role_file(machine['name'])
  end

  def generate_role_file(name)
    box = @mdbci_config.node_configurations[name]['box']
    recipe_name = @env.repos.recipe_name(@product)
    product = @mdbci_config.node_configurations[name]['product']
    if product.nil?
      product = {'name' => @product, 'version' => @product_version.to_s}
    else
      product < {'name' => @product, 'version' => @product_version.to_s}
    end
    product_config = generate_product_config(@product, product, box)
    role_json_file = generate_json_file(name, product_config, recipe_name, box)
    IO.write("#{@mdbci_config.path}/#{name}_new.json", role_json_file)

  end

  def generate_json_file(name, product_config, recipe_name, box)
    run_list = ['recipe[mdbci_provision_mark::remove_mark]',
                "recipe[#{recipe_name}]",
                'recipe[mdbci_provision_mark::default]']
    role = { name: name,
             default_attributes: {},
             override_attributes: product_config,
             json_class: 'Chef::Role',
             description: '',
             chef_type: 'role',
             run_list: run_list }
    JSON.pretty_generate(role)
  end

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

  # Check whether chef have provisioned the server or not
  #
  # @param machine [Hash] information about machine to connect
  # @param logger [Out] logger to log information
  def node_provisioned?(machine, logger)
    exit_code = SUCCESS_RESULT
    @machine_configurator.within_ssh_session(machine) do |ssh|
      output = ssh.exec!('test -e /var/mdbci/provisioned && printf PROVISIONED || printf NOT')
      if output == 'PROVISIONED'
        logger.info("Node '#{machine['name']}' was configured.")
      else
        logger.error("Node '#{machine['name']}' is not configured.")
        exit_code = ERROR_RESULT
      end
    end
    exit_code
   end
end

# Install product class

# This class installs the product on selected node.
require_relative 'generate_command'
class InstallProduct < BaseCommand

  # This method is called whenever the command is executed
  def execute
    exit_code = SUCCESS_RESULT
    if @env.show_help
      show_help
      return SUCCESS_RESULT
    end
    return ARGUMENT_ERROR_RESULT unless init == SUCCESS_RESULT
    
    machine = setup_ssh_key(@mdbci_config.node_names[0])
    result = install_product(machine)
    exit_code = ERROR_RESULT if result == ERROR_RESULT
    
    exit_code
  end

  # Print brief instructions on how to use the command.
  def show_help
    info = <<-HELP
 'install_product'  Install a product onto the configuration node.
 mdbci install_product config/node
    HELP
    @ui.info(info)
  end

  # Initializes the command variable.
  def init
    if @args.first.nil?
      @ui.error('Please specify the configuration')
      return ARGUMENT_ERROR_RESULT
    end
    @mdbci_config = Configuration.new(@args.first, @env.labels)
    p @mdbci_config
    
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
    exit_code = SUCCESS_RESULT
    solo_config = "#{machine['name']}-config.json"
    role_file = "#{@mdbci_config.path}/#{machine['name']}.json"
    extra_files = [
      [role_file, "roles/#{machine['name']}.json"],
      ["#{@mdbci_config.path}/#{machine['name']}-config.json", "configs/#{solo_config}"]
    ]
    @machine_configurator.configure(machine, solo_config, @ui, extra_files)
    #node_provisioned?(machine['name'], logger)
    exit_code
  end
end

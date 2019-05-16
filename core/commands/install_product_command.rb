# Install product class

# This class installs the product on selected node.
class InstallProduct < BaseCommand

  # This method is called whenever the command is executed
  def execute
    exit_code = SUCCESS_RESULT
    if @env.show_help
      show_help
      return SUCCESS_RESULT
    end
    return ARGUMENT_ERROR_RESULT unless init == SUCCESS_RESULT
    
    ssh_connection_parameters = setup_ssh_key(@mdbci_config.node_names[0])
    result = configure_server_ssh_key(ssh_connection_parameters)
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
    
    begin
      @network_config = NetworkSettings.from_file(@mdbci_config.network_settings_file)
    rescue StandardError
      @ui.error('Network settings file is not found for the configuration')
      return ARGUMENT_ERROR_RESULT
    end
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
  
  # Connect and add install product on server
  # @param machine [Hash] information about machine to connect
  def configure_server_ssh_key(machine)
    exit_code = SUCCESS_RESULT
    options = Net::SSH.configuration_for(machine['network'], true)
    options[:auth_methods] = %w[publickey none]
    options[:verify_host_key] = false
    options[:keys] = [machine['keyfile']]
    begin
      Net::SSH.start(machine['network'], machine['whoami'], options) do |ssh|
        
      end
    rescue StandardError
      @ui.error("Could not initiate connection to the node '#{machine['name']}'")
      exit_code = ERROR_RESULT
    end
    exit_code
  end

  def install_product

  end

end


# frozen_string_literal: true

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
    exit_code = install_product(machine)

    exit_code
  end

  # Print brief instructions on how to use the command.
  def show_help
    info = <<~HELP
  'install_product' Install a product onto the configuration node.
  mdbci install_product config/node --product product --version-product version
    HELP
    @ui.info(info)
  end

  # Initializes the command variable.
  def init
    if @args.first.nil?
      @ui.error('Please specify the node')
      return ARGUMENT_ERROR_RESULT
    end
    @mdbci_config = Configuration.new(@args.first, @env.labels)

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
  def setup_ssh_key(node_name)3
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
    extra_files = [
      [role_file, "roles/#{machine['name']}.json"],
      ["#{@mdbci_config.path}/#{machine['name']}-config.json", "configs/#{solo_config}"]
    ]
    @machine_configurator.configure(machine, solo_config, @ui, extra_files)
    node_provisioned?(machine, @ui)
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

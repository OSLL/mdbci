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
    exit_code
  end

  # Print brief instructions on how to use the command.
  def show_help
    info = <<-HELP
 'install_product'  Install a product onto the configuration node.
 mdbci install_product node
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

  def install_product

  end

end


# frozen_string_literal: true

require_relative 'base_command'
require_relative '../models/configuration'
require_relative '../services/shell_commands'
require_relative '../services/machine_configurator'
require_relative '../services/network_config'
require_relative 'generate_command'
require_relative 'destroy_command'
require_relative '../services/log_storage'

# The command sets up the environment specified in the configuration file.
class UpCommand < BaseCommand
  include ShellCommands

  def self.synopsis
    'Setup environment as specified in the configuration.'
  end

  # rubocop:disable Metrics/MethodLength
  def show_help
    info = <<-HELP
'up' starts virtual machines in the specified configuration.

mdbci up config - configure all VMs in the specified configuration.

mdbci up config/node - configure the specified node from the configuration.

OPTIONS:
  --attempts [number]:
Specifies the number of times VM will be destroyed durintg the provisioning.
  --threads [number]:
Specifies the number of threads for parallel configuration of virtual machines.
  --recreate:
Specifies that existing VMs must be destroyed before the configuration of all target VMs.
  -l, --labels [string]:
Specifies the list of desired labels. It allows to filter VMs based on the label presence.
If any of the labels passed to the command match any label in the machine description,
then this machine will be brought up and configured according to its configuration.
Labels should be separated with commas and should not contain any whitespaces.
    HELP
    @ui.info(info)
  end
  # rubocop:enable Metrics/MethodLength

  VAGRANT_NO_PARALLEL = '--no-parallel'

  # Checks that all required parameters are passed to the command
  # and set them as instance variables.
  #
  # @raise [ArgumentError] if unable to parse arguments.
  def setup_command
    if @args.empty? || @args.first.nil?
      raise ArgumentError, 'You must specify path to the mdbci configuration as a parameter.'
    end

    @specification = @args.first
    @attempts = @env.attempts&.to_i || 5
    @box_manager = @env.boxes
    @machine_configurator = MachineConfigurator.new(@ui)
    @config = Configuration.new(@specification, @env.labels)
    Workers.pool.resize(@env.threads_count)
  end

  # Generate flags based upon the configuration
  #
  # @param provider [String] name of the provider to work with
  # @return [String] flags that should be passed to Vagrant commands
  def generate_vagrant_run_flags(provider)
    flags = []
    flags.push(VAGRANT_NO_PARALLEL) if provider == 'aws'
    flags.uniq.join(' ')
  end

  # Check whether node is running or not.
  #
  # @param node [String] name of the node to get status from.
  # @param logger [Out] logger to log information to
  # @return [Boolean]
  def node_running?(node, logger)
    result = run_command("vagrant status #{node}", {}, logger)
    status_regex = /^#{node}\s+(.+)\s+(\(.+\))?\s$/
    status = if result[:output] =~ status_regex
               result[:output].match(status_regex)[1]
             else
               'UNKNOWN'
             end
    logger.info("Node '#{node}' status: #{status}")
    if status&.include?('running')
      logger.info("Node '#{node}' is running.")
      true
    else
      logger.info("Node '#{node}' is not running.")
      false
    end
  end

  # Check whether chef was successfully installed on the machine or not
  #
  # @param node [String] name of the node to check.
  # @param logger [Out] logger to log information to
  # @return [Boolean]
  def chef_installed?(node, logger)
    result = run_command("vagrant ssh #{node} -c "\
                         '"test -e /var/chef/cache/chef-stacktrace.out && printf FOUND || printf NOT_FOUND"',
                         {}, logger)
    chef_stacktrace = result[:output]
    if chef_stacktrace == 'FOUND'
      logger.error("Chef on node '#{node}' was installed with error.")
      false
    else
      logger.info("Chef on node '#{node}' was successfully installed.")
      true
    end
  end

  # Check whether chef have provisioned the server or not
  #
  # @param node [String] name of the node to check
  # @param logger [Out] logger to log information to
  # return [Boolean]
  def node_provisioned?(node, logger)
    result = run_command("vagrant ssh #{node} -c"\
                         '"test -e /var/mdbci/provisioned && printf PROVISIONED || printf NOT"',
                         {}, logger)
    provision_file = result[:output]
    if provision_file == 'PROVISIONED'
      logger.info("Node '#{node}' was configured.")
      true
    else
      logger.error("Node '#{node}' is not configured.")
      false
    end
  end

  # Split list of nodes between running and halt ones
  #
  # @param nodes [Array<String] name of nodes to check
  # @param logger [Out] logger to log information to.
  # @return [Array<String>, Array<String>] nodes that are running and those that are not
  def running_and_halt_nodes(nodes, logger)
    nodes.partition { |node| node_running?(node, logger) }
  end

  # Check that specified node is brought up.
  #
  # @param node [String] name of node that should be checked.
  # @param logger [Out] logger to log information to.
  # @return [Bool] true if node needs to be re-created.
  def broken_node?(node, logger)
    !(node_running?(node, logger) && chef_installed?(node, logger))
  end

  # Check that specified node is configured.
  #
  # @param node [String] name of node that should be checked.
  # @param logger [Out] logger to log information to.
  # @return [Bool] true if node needs to be re-provisioned.
  def unconfigured_node?(node, logger)
    return false if broken_node?(node, logger)

    !node_provisioned?(node, logger)
  end

  # Configure single node using the chef-solo respected role
  #
  # @param node [String] name of the node
  # @param logger [Out] logger to log information to
  # @return [Boolean] whether we were successful or not
  def configure(node, logger)
    @network_config.add_nodes([node])
    solo_config = "#{node}-config.json"
    role_file = GenerateCommand.role_file_name(@config.path, node)
    unless File.exist?(role_file)
      logger.info("Machine '#{node}' should not be configured. Skipping.")
      return true
    end
    extra_files = [
      [role_file, "roles/#{node}.json"],
      [GenerateCommand.node_config_file_name(@config.path, node), "configs/#{solo_config}"]
    ]
    @machine_configurator.configure(@network_config[node], solo_config, logger, extra_files)
    node_provisioned?(node, logger)
  end

  # Bring up whole configuration or a machine up.
  #
  # @param provider [String] name of the provider to use.
  # @param logger [Out] logger to log information to
  # @param node [String] node name to bring up. It can be empty if we need to bring
  # the whole configuration up.
  # @return result of the run_command_and_log()
  def bring_up_machine(provider, logger, node = '')
    logger.info("Bringing up #{(node.empty? ? 'configuration ' : 'node ')} #{@specification}")
    vagrant_flags = generate_vagrant_run_flags(provider)
    run_command_and_log("vagrant up #{vagrant_flags} --provider=#{provider} #{node}", true, {}, logger)
  end

  # Provide information for the end-user where to find the required information
  #
  # @param working_directory [String] path to the current working directory
  def generate_config_information(working_directory)
    network_config_path = "#{@config.path}#{Configuration::NETWORK_FILE_SUFFIX}"
    @ui.info('All nodes were brought up and configured.')
    @ui.info("DIR_PWD=#{working_directory}")
    @ui.info("CONF_PATH=#{@config.path}")
    @ui.info("Generating #{network_config_path} file")
    File.write(network_config_path, @network_config.ini_format)
  end

  # Provide information to the users about which labels are running right now
  def generate_label_information_file
    labels_config_path = "#{@config.path}#{Configuration::LABELS_INFO_FILE_SUFFIX}"
    @ui.info("Generating labels information file, '#{labels_config_path}'")
    File.write(labels_config_path, @network_config.active_labels.sort.join(','))
  end

  # Forcefully destroys given node
  #
  # @param node [String] name of node which needs to be destroyed
  # @param logger [Out] logger to log information to
  def destroy_node(node, logger)
    logger.info("Destroying '#{node}' node.")
    DestroyCommand.execute(["#{@config.path}/#{node}"], @env, logger, keep_template: true)
  end

  # Restores network configuration of nodes that were already brought up
  def store_network_config
    @network_config = NetworkConfig.new(@config, @ui)
    running_nodes = running_and_halt_nodes(@config.node_names, @ui)[0]
    @network_config.add_nodes(running_nodes)
  end

  # Switch to the working directory, so all Vagrant commands will
  # be run in corresponding directory. The directory will be returned
  # to the invoking one after the completion.
  #
  # @param directory [String] path to the directory to switch to.
  def run_in_directory(directory)
    current_dir = Dir.pwd
    Dir.chdir(directory)
    yield
    Dir.chdir(current_dir)
  end

  # Create and configure node, or recreate if it needs to fix.
  #
  # @param node [String] name of node which needs to be configured
  # @param logger [Out] logger to log information to
  # @return [Bool] configuration result
  def bring_up_and_configure(node, logger)
    force_recreate = false
    @attempts.times do |attempt|
      @ui.info("Bring up and configure node #{node}. Attempt #{attempt + 1}.")
      destroy_node(node, logger) if force_recreate
      bring_up_machine(@config.provider, logger, node) unless node_running?(node, logger)
      unless node_running?(node, logger)
        force_recreate = true
        next
      end
      return true if configure(node, logger)
    end
    false
  end

  # Get the logger. Depending on the number of threads returns a unique logger or @ui.
  #
  # @return [Out] logger.
  def retrieve_logger_for_node
    @env.threads_count > 1 ? LogStorage.new(@env) : @ui
  end

  # Brings up node.
  #
  # @param node [String] name of node which needs to be up
  # @return [Array<Bool, Out>] up result and log history.
  # rubocop:disable Style/IfUnlessModifier
  def up_node(node)
    logger = retrieve_logger_for_node
    if @env.recreate || !node_running?(node, logger)
      bring_up_and_configure(node, logger)
    end
    if broken_node?(node, @ui)
      @ui.error("Node '#{node}' was not brought up")
      return [false, logger]
    elsif unconfigured_node?(node, @ui)
      @ui.error("Node '#{node}' was not configured")
      return [false, logger]
    end

    [true, logger]
  end
  # rubocop:enable Style/IfUnlessModifier

  # Brings up nodes
  #
  # @return [Number] execution status
  def up
    nodes = @config.node_names
    run_in_directory(@config.path) do
      store_network_config
      up_results = Workers.map(nodes) { |node| up_node(node) }
      up_results.each { |up_result| up_result[1].print_to_stdout } if @env.threads_count > 1
      return ERROR_RESULT unless up_results.detect { |up_result| !up_result[0] }.nil?
    end
    generate_config_information(Dir.pwd)
    generate_label_information_file
    SUCCESS_RESULT
  end

  def execute
    if @env.show_help
      show_help
      return SUCCESS_RESULT
    end
    begin
      setup_command
      up
    rescue ArgumentError => error
      @ui.error error.message
      @ui.error error.backtrace.join("\n")
      return ARGUMENT_ERROR_RESULT
    end
  end
end

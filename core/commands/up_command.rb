# frozen_string_literal: true

require_relative 'base_command'
require_relative '../docker_manager'
require_relative '../models/configuration'

# The command sets up the environment specified in the configuration file.
class UpCommand < BaseCommand
  def self.synopsis
    'Setup environment as specified in the configuration'
  end

  VAGRANT_NO_PARALLEL = '--no-parallel'

  # Checks that all required parameters are passed to the command
  # and set them as instance variables.
  #
  # @raise [ArgumentError] if unable to parse arguments.
  def setup_command
    if @args.empty? || @args.first.nil?
      raise ArgumentError, 'You must specify path to the mdbci configuration as a parameter.'
    end
    @configuration = @args.first

    @attempts = if @env.attempts.nil?
                  5
                else
                  @env.attempts.to_i
                end
    self
  end

  # Method parses up command configuration and extracts path to the
  # configuration and node name if specified.
  #
  # @raise [ArgumentError] if path to the configuration is invalid
  def parse_configuration
    config, node = Configuration.parse_spec(@configuration)
    if node.empty?
      @ui.info "Node #{node} is specified in #{@configuration}"
    else
      @ui.info "Node is not specified in #{@configuration}"
    end
    [config.path, node]
  end

  # Read template from the specified configuration.
  #
  # @param config_path [String] path to the configuration.
  #
  # @returns [Hash] produced by parsing JSON.
  #
  # @raise [ArgumentError] if there is an error during template configuration.
  def read_template(config_path)
    template_file_name_path = "#{config_path}/template"
    unless File.exist?(template_file_name_path)
      raise ArgumentError, "There is no template configuration specified in #{config_path}."
    end
    template_path = File.read(template_file_name_path)
    unless File.exist?(template_path)
      raise ArgumentError, "The template #{template_path} specified in #{template_file_name_path} does not exist."
    end
    JSON.parse(File.read(template_path))
  end

  # Read node provider specified in the configuration.
  #
  # @return [String] name of the provider specified in the file.
  #
  # @raise ArgumentError if there is no file or invalid provider specified.
  def read_provider(config_path)
    provider_file_path = "#{config_path}/provider"
    unless File.exist?(provider_file_path)
      raise ArgumentError, "There is no provider configuration specified in #{config_path}."
    end
    provider = File.read(provider_file_path).strip
    if provider == 'mdbci'
      raise ArgumentError, 'You are using mdbci node template. Please generate valid one before running up command.'
    end
    @ui.info "Using provider: #{provider}"
    provider
  end

  # Generate docker images, so they will not be loaded during production
  #
  # @param config [Hash] configuration read from the template
  # @param nodes_directory [String] path to the directory where they are located
  def generate_docker_images(config, nodes_directory)
    @ui.info 'Generating docker images.'
    config.each do |node|
      unless node[1]['box'].nil?
        DockerManager.build_image("#{nodes_directory}/#{node[0]}", node[1]['box'])
      end
    end
  end

  # Generate flags based upon the configuration
  #
  # @param provider [String] name of the provider to work with
  #
  # @return [String] flags that should be passed to Vagrant commands
  def generate_vagrant_run_flags(provider)
    flags = []
    if (provider == 'aws') || (provider == 'docker')
      flags << VAGRANT_NO_PARALLEL
    end
    flags.join(' ')
  end

  # Execute the command, log stdout and stderr
  #
  # @param command [String] command to run
  #
  # @return [Process::Status] of the run command
  def run_command_and_log(command)
    @ui.info "Invoking command: #{command}"
    Open3.popen3(command) do |_stdin, stdout, stderr, wthr|
      stdout.each_line do |line|
        @ui.info line
      end
      stderr.each_line do |line|
        @ui.error line
      end
      wthr.value
    end
  end

  # Find out names of the machines for this vagrant configuration.
  # Currently it relies on the format of vagrant status command.
  #
  # @return [Array<String>] names of the nodes
  def fetch_node_names
    node_lines = `vagrant status`.split("\n\n")[1].split("\n")
    node_lines.map { |line| line.split(/\s+/)[0] }
  end

  # Check whether node is running or not.
  #
  # @param node [String] name of the node to get status from.
  # @return [Boolean]
  def node_running?(node)
    status = `vagrant status #{node}`.split("\n")[2]
    @ui.info "Node '#{node}' status: #{status}"
    if status.include? 'running'
      @ui.info "Node '#{node}' is running."
      true
    else
      @ui.error "Node '#{node}' is not running."
      false
    end
  end

  # Check whether chef was successfully installed on the machine or not
  #
  # @param node [String] name of the node to check.
  # @return [Boolean]
  def chef_installed?(node)
    command = "vagrant ssh #{node} -c "\
              '"test -e /var/chef/cache/chef-stacktrace.out && printf FOUND || printf NOT_FOUND"'
    chef_stacktrace = `#{command}`
    if chef_stacktrace == 'FOUND'
      @ui.error "Chef on node '#{node}' was installed with error."
      false
    else
      @ui.info "Chef on node '#{node}' was successfully installed."
      true
    end
  end

  # Check whether chef have provisioned the server or not
  #
  # @param node [String] name of the node to check
  # return [Boolean]
  def node_provisioned?(node)
    command = "vagrant ssh #{node} -c"\
                     '"test -e /var/mdbci/provisioned && printf PROVISIONED || printf NOT"'
    provision_file = `#{command}`
    if provision_file == 'PROVISIONED'
      @ui.info "Node '#{node}' was configured."
      true
    else
      @ui.error "Node '#{node}' is not configured."
      false
    end
  end

  # Check that all specified nodes are configured and brought up.
  # Return list of nodes that needs to be re-created or re-provisioned.
  #
  # @param nodes [Array<String>] name of nodes that should be checked.
  # @return [Array<String>, Array<String>] nodes to recreate and nodes to re-provision.
  def check_nodes(nodes)
    recreate = []
    reconfigure = []
    nodes.each do |node|
      unless node_running?(node) && chef_installed?(node)
        recreate.push node
        next
      end
      reconfigure.push(node) unless node_provisioned?(node)
    end
    [recreate, reconfigure]
  end

  # Try to reconfigure the specified nodes. If the operation was not
  # successfull, return them as a list of nodes to be reproduced.
  #
  # @param nodes [Array<String>] list of node names to be reconfigureed.
  # @return [Array<String>] list of nodes that were not reconfigureed.
  def reconfigure(nodes)
    nodes.reject do |node|
      @ui.info "Trying to configure node '#{node}'."
      run_command_and_log("vagrant provision #{node}")
      node_provisioned?(node)
    end
  end

  # Destroy and then create specified nodes.
  #
  # @param nodes [Array<String>] list of nodes that should be re-created
  # @param provider [String] name of virtual box provider
  def recreate(nodes, provider)
    nodes.each do |node|
      @ui.info "Destroying '#{node}' node."
      run_command_and_log("vagrant destroy --force #{node}")
      @ui.info "Creating '#{node}' node."
      run_command_and_log("vagrant up #{node} --provider=#{provider}")
    end
  end

  # Check that nodes were brougt up and configrued. If they were not
  # configured, then try to reconfigure them
  #
  # @param nodes_to_check [Array<String>] list of nodes to check
  # @return [Array<String>] list of nodes that are still misconfigured.
  def check_and_configure_nodes(nodes_to_check)
    halt_nodes, unconfigured_nodes = check_nodes(nodes_to_check)
    halt_nodes.concat(reconfigure(unconfigured_nodes))
  end

  # Destroy all existing nodes and setup configuration
  #
  # @param template [Hash] template that was used to setup the provision.
  # @param nodes_provider [String] name of the node provider to use
  # @param node [String] name of the node to bring up
  # @return [Array<String>] list of nodes that should be checked
  def setup_nodes(template, nodes_provider, node = '')
    generate_docker_images(template, '.') if nodes_provider == 'docker'
    @ui.info 'Destroying existing nodes.'
    run_command_and_log("vagrant destroy --force #{node}")

    vagrant_flags = generate_vagrant_run_flags(nodes_provider)
    @ui.info "Bringing up #{(node.empty? ? 'configuration ' : 'node ')} #{@configuration}"
    run_command_and_log("vagrant up #{vagrant_flags} --provider=#{nodes_provider} #{node}")
    nodes_to_check = if node.empty?
                       fetch_node_names
                     else
                       [node]
                     end
    check_and_configure_nodes(nodes_to_check)
  end

  # Try to fix nodes that were not brought up. Try to reconfigure them.
  # If any operation fails, try to repair them several times.
  #
  # @param nodes_to_fix [Array<String>] list of node names to fix.
  # @param nodes_provider [String] name of the provider.
  # @return [Boolean]
  def fix_nodes(nodes_to_fix, nodes_provider)
    @attempts.times do |attempt|
      @ui.info "Checking that nodes were brought up. Attempt #{attempt + 1}"
      recreate(nodes_to_fix, nodes_provider)
      nodes_to_fix = check_and_configure_nodes(nodes_to_fix)
      break if nodes_to_fix.empty?
    end

    broken_nodes, unconfigured_nodes = check_nodes(nodes_to_fix)
    unless broken_nodes.empty? && unconfigured_nodes.empty?
      @ui.error "The following nodes were not brought up: #{broken_nodes.join(', ')}"
      @ui.error "The following nodes were not configured: #{unconfigured_nodes.join(', ')}"
      return false
    end
    true
  end

  # Provide information for the end-user where to find the required information
  # @param working_directory [String] path to the current working directory
  # @param config_path [String] path to the configuration
  # @param node [String] name of the node that was brought up
  def generate_config_information(working_directory, config_path, node = '')
    @ui.info 'All nodes were brought up and configured.'
    @ui.info "DIR_PWD=#{working_directory}"
    @ui.info "CONF_PATH=#{config_path}"
    @ui.info "Generating #{config_path}_network_settings file"
    printConfigurationNetworkInfoToFile(config_path, node)
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

  def execute
    begin
      setup_command
      config_path, node = parse_configuration
      template = read_template(config_path)
      nodes_provider = read_provider(config_path)
    rescue ArgumentError => error
      @ui.warning error.message
      return ARGUMENT_ERROR_RESULT
    end
    run_in_directory(config_path) do
      nodes_to_fix = setup_nodes(template, nodes_provider, node)
      return ERROR_RESULT unless fix_nodes(nodes_to_fix, nodes_provider)
    end
    generate_config_information(Dir.pwd, config_path, node)
    SUCCESS_RESULT
  end
end

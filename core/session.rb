require 'json-schema'
require 'json'
require 'fileutils'
require 'uri'
require 'open3'
require 'xdg'
require 'concurrent'

require_relative 'clone'
require_relative 'commands/up_command'
require_relative 'commands/sudo_command'
require_relative 'commands/snapshot_command'
require_relative 'commands/destroy_command'
require_relative 'commands/generate_command'
require_relative 'commands/generate_product_repositories_command'
require_relative 'commands/help_command'
require_relative 'commands/configure_command'
require_relative 'commands/public_keys_command'
require_relative 'commands/deploy_command'
require_relative 'commands/setup_dependencies_command'
require_relative 'commands/show_network_config_command'
require_relative 'commands/install_product_command.rb'
require_relative 'constants'
require_relative 'helper'
require_relative 'models/configuration'
require_relative 'models/tool_configuration'
require_relative 'network'
require_relative 'out'
require_relative 'services/repo_manager'
require_relative 'services/aws_service'
require_relative 'services/shell_commands'
require_relative 'services/box_definitions'

# Currently it is the GOD object that contains configuration and manages the commands that should be run.
# These responsibilites should be split between several classes.
class Session
  attr_reader :box_definitions
  attr_accessor :configs
  attr_accessor :configuration_file
  attr_accessor :versions
  attr_accessor :template_file
  attr_accessor :boxes_location
  attr_accessor :boxName
  attr_accessor :field
  attr_accessor :override
  attr_accessor :isSilent
  attr_accessor :command
  attr_accessor :repos
  attr_accessor :repo_dir
  attr_accessor :mdbciNodes # mdbci nodes
  attr_accessor :templateNodes
  attr_accessor :attempts
  attr_accessor :mdbciDir
  attr_accessor :mdbci_dir
  attr_accessor :starting_dir
  attr_accessor :working_dir
  attr_accessor :nodeProduct
  attr_accessor :productVersion
  attr_accessor :keyFile
  attr_accessor :keep_template
  attr_accessor :list
  attr_accessor :boxPlatform
  attr_accessor :boxPlatformVersion
  attr_accessor :path_to_nodes
  attr_accessor :node_name
  attr_accessor :snapshot_name
  attr_accessor :ipv6
  attr_reader :aws_service
  attr_reader :tool_config
  attr_reader :rhel_credentials
  attr_accessor :show_help
  attr_accessor :reinstall
  attr_accessor :recreate
  attr_accessor :labels
  attr_accessor :force_distro
  attr_accessor :cpu_count
  attr_accessor :threads_count

  PLATFORM = 'platform'
  VAGRANT_NO_PARALLEL = '--no-parallel'

  CHEF_NOT_FOUND_ERROR = <<EOF
The chef binary (either `chef-solo` or `chef-client`) was not found on
the VM and is required for chef provisioning. Please verify that chef
is installed and that the binary is available on the PATH.
EOF

  OUTPUT_NODE_NAME_REGEX = "==>\s+(.*):{1}"

  def initialize
    @mdbciNodes = {}
    @templateNodes = {}
    @keep_template = false
    @list = false
    @threads_count = Concurrent.physical_processor_count
  end

  # Fill in paths based on the provided configuration if they were
  # not setup via external configuration
  def fill_paths
    @mdbci_dir = __dir__ unless @mdbci_dir
    @working_dir = Dir.pwd unless @working_dir
    @starting_dir = @working_dir unless @starting_dir
    @configuration_directories = [
      File.join(XDG['CONFIG_HOME'].to_s, 'mdbci'),
      File.join(@mdbci_dir, 'config')
    ]
  end

  # Method initializes services that depend on the parsed configuration
  def initialize_services
    fill_paths
    $out.info('Loading MDBCI configuration file')
    @tool_config = ToolConfiguration.load
    $out.info('Loading repository configuration files')
    @repos = RepoManager.new($out, @repo_dir)
    if @tool_config['aws']
      @aws_service = AwsService.new(@tool_config['aws'], $out)
    end
    @rhel_credentials = @tool_config['rhel']
    @box_definitions = BoxDefinitions.new(@boxes_location)
  end

  # Search for a configuration file in all known configuration locations that include
  # XDG['CONFIG'] directories and mdbci/config directory.
  # @param [String] name of the file or directory to locate in the configuration.
  # @return [String] absolute path to the found resource in one of the directories.
  # @raise [RuntimeError] if unable to find the specified configuration resource.
  def find_configuration(name)
    @configuration_directories.each do |directory|
      full_path = File.join(directory, name)
      return full_path if File.exist?(full_path)
    end
    raise "Unable to find configuration '#{name}' in the following directories: #{@configuration_directories.join(', ')}"
  end

  # Get the path to the user configuration directory
  # @param [String] name of the resource in the configuration directory
  # @return [String] full path to the resource
  def configuration_path(name = '')
    configuration_dir = File.join(XDG['CONFIG_HOME'].to_s, 'mdbci')
    FileUtils.mkdir_p(configuration_dir)
    File.join(configuration_dir, name)
  end

  # Get the path to the user data directory
  # @param [String] name of the resource in data directory
  # @param [String] full path to the data resource
  def data_path(name = '')
    data_dir = File.join(XDG['DATA_HOME'].to_s, 'mdbci')
    FileUtils.mkdir_p(data_dir)
    File.join(data_dir, name)
  end

  def setup(what)
    case what
    when 'boxes'
      $out.info('Adding boxes to vagrant')
      @box_definitions.each_definition do |name, definition|
        next if %w[aws mdbci].include?(definition['provider'])

        command = if definition['box'] =~ URI::REGEXP
                    "vagrant box add #{name} #{definition['box']}"
                  else
                    "vagrant box add --provider #{definition['provider']} #{definition['box']}"
                  end
        result = ShellCommands.run_command_and_log($out, "#{command} 2>&1")

        if !result[:value].success? && !result[:output].include?('already exists')
          $out.error("Unable to add the box #{name} to the Vagrant")
          return 1
        end
      end
      0
    else
      $out.error("Do not know how to setup #{what}")
      1
    end
  end

  # load template nodes
  def loadTemplateNodes()
    pwd = Dir.pwd
    instanceFile = $exception_handler.handle('INSTANCE configuration file not found') { IO.read(pwd+'/template') }
    $out.info 'Load nodes from template file ' + instanceFile.to_s
    @templateNodes = $exception_handler.handle('INSTANCE configuration file invalid') { JSON.parse(IO.read(instanceFile)) }
    if @templateNodes.has_key?('cookbook_path');
      @templateNodes.delete('cookbook_path');
    end
    if @templateNodes.has_key?('aws_config');
      @templateNodes.delete('aws_config');
    end
  end

  # load mdbci nodes
  def loadMdbciNodes(path)
    templateFile = $exception_handler.handle('MDBCI configuration file not found') { IO.read(path+'/mdbci_template') }
    $out.info 'Read template file ' + templateFile.to_s
    @mdbciNodes = $exception_handler.handle('MDBCI configuration file invalid') { JSON.parse(IO.read(templateFile)) }
    # delete cookbook_path and aws_config
    if @mdbciNodes.has_key?("cookbook_path");
      @mdbciNodes.delete("cookbook_path");
    end
    if @mdbciNodes.has_key?("aws_config");
      @mdbciNodes.delete("aws_config");
    end
  end

  # ./mdbci ssh command for AWS, VBox and PPC64 machines
  def ssh(args)
    result_ssh = getSSH(args,"")
    result_ssh.each do |ssh_out|
      $out.out ssh_out
    end
    return 0
  end

  def getSSH(args,command)
    result = Array.new()
    pwd = Dir.pwd
    $session.command = command unless command.empty?
    raise 'Configuration name is required' if args.nil?
    params = args.split('/')
    dir, node_arg = extract_directory_and_node(args)
    # mdbci ppc64 boxes
    if File.exist?(dir+'/mdbci_template')
      loadMdbciNodes dir
      if node_arg.nil? # ssh for all nodes
        @mdbciNodes.each do |node|
            cmd = createCmd(params,node,pwd)
            result.push(runSSH(cmd, params))
        end
      else
        mdbci_node = @mdbciNodes.find { |elem| elem[0].to_s == node_arg }
        raise "mdbci node with such name does not exist in #{dir}: #{node_arg}" if mdbci_node.nil?
        cmd = createCmd(params,mdbci_node,pwd)
        result.push(runSSH(cmd, params))
      end
    else # aws, vbox nodes
      raise "Machine with such name: #{dir} does not exist" unless Dir.exist?(dir)
      begin
        nodes = get_nodes(File.absolute_path(dir))
        Dir.chdir dir
        if node_arg.nil? # ssh for all nodes
          nodes.each do |node|
            cmd = "vagrant ssh #{node} -c \"#{$session.command}\""
            result.push(runSSH(cmd,params))
          end
        else
          raise "node with such name does not exist in #{dir}: #{node_arg}" unless nodes.include? node_arg
          cmd = "vagrant ssh #{node_arg} -c \"#{$session.command}\""
          result.push(runSSH(cmd,params))
        end
      ensure
        Dir.chdir pwd
      end
    end
    return result
  end

  def createCmd(params, node, pwd)
    dir = params[0]
    node_arg =  params[1]
    box = node[1]['box'].to_s
    raise "Box: #{box} is empty" if box.empty?

    box_params = $session.box_definitions.get_box(box)
    cmd = 'ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ' + $mdbci_exec_dir.to_s+'/KEYS/'+box_params['keyfile'].to_s + " "\
                    + box_params['user'].to_s + "@"\
                    + box_params['IP'].to_s + " "\
                    + "'" + $session.command + "'"
    return cmd
  end

  def runSSH(cmd, params)
    dir = params[0]
    node_arg = params[1]
    $out.info 'Running ['+cmd+'] on '+dir.to_s+'/'+node_arg.to_s
    result = ShellCommands.run_command_and_log($out, cmd)
    unless result[:value].success?
      raise "'#{cmd}' command returned non-zero exit code: (#{result[:value].exitstatus})"
    end
    result[:output]
  end

  def show_box_keys
    if @field.nil? || @field.empty?
      $out.error('Please specify the field to get summarized data')
      return 1
    end
    $out.out(@box_definitions.unique_values(@field))
    0
  end

  def show_platforms
    $out.out(@box_definitions.unique_values('platform'))
    0
  end

  # show boxes with platform and version
  def show_boxes
    if @boxPlatform.nil?
      $out.warning('Required parameter --platform is not defined.')
      $out.info('Full command specification:')
      $out.info('./mdbci show boxes --platform PLATFORM [--platform-version VERSION]')
      return 1
    end
    # check for undefined box platform
    some_box = @box_definitions.find { |_, definition| definition['platform'] == @boxPlatform }
    if some_box.nil?
      $out.error("Platform #{@boxPlatform} is not supported!")
      return 1
    end

    platform_name = if @boxPlatformVersion.nil?
                      @boxPlatform
                    else
                      "#{@boxPlatform}^#{@boxPlatformVersion}"
                    end
    $out.info("List of boxes for the #{platform_name} platform:")
    boxes = @box_definitions.select do |_, definition|
      definition['platform'] == @boxPlatform &&
        (@boxPlatformVersion.nil? || definition['platform_version'] == @boxPlatformVersion)
    end
    boxes.each { |name, _| $out.out(name) }
    boxes.size != 0
  end

  def showBoxField
    $out.out findBoxField($session.boxName, $session.field)
    return 0
  end

  def findBoxField(boxName, field)
    box = $session.box_definitions.get_box(boxName)
    if box == nil
      raise "Box #{boxName} is not found"
    end

    if field != nil
      if !box.has_key?(field)
        raise "Box #{boxName} does not have #{field} key"
      end
      return box[field]
    else
      return box.to_json
    end
  end


  def show_box_name_in_configuration(path = nil)
    if path.nil?
      $out.warning('Please specify the path to the nodes configuration as a parameter')
      return 2
    end
    configuration = Configuration.new(path)
    if configuration.node_names.size != 1
      $out.warning('Please specify the node to get configuration from')
      return 2
    end
    $out.out(configuration.box_names(configuration.node_names.first))
    0
  end

  def validate_template
    raise 'Template must be specified!' unless $session.template_file
    begin
      schema = JSON.parse(File.read 'templates/schemas/template.json')
      json = JSON.parse(File.read $session.template_file)
      JSON::Validator.validate!(schema, json)
      $out.info "Template #{$session.template_file} is valid"
    rescue JSON::Schema::ValidationError => e
      $out.error "Template #{$session.template_file} is NOT valid"
      raise e.message
    end
    return 0
  end

  # List of actions that are provided by the show command.
  SHOW_COMMAND_ACTIONS = {
    box: {
      description: 'Show box name based on the path to the configuration file',
      action: ->(*params) { show_box_name_in_configuration(*params) }
    },
    boxes: {
      description: 'List available boxes',
      action: ->(*) { show_boxes }
    },
    boxinfo: {
      description: 'Show the field value of the box configuration',
      action: ->(*) { showBoxField }
    },
    boxkeys: {
      description: 'Show keys for all configured boxes',
      action: ->(*) { show_box_keys }
    },
    keyfile: {
      description: 'Show box key file to access it',
      action: ->(*params) { Network.showKeyFile(*params) }
    },
    help: {
      description: 'Print list of available actions and exit',
      action: ->(*) { display_usage_info('show', SHOW_COMMAND_ACTIONS) }
    },
    network: {
      description: 'Show network interface configuration',
      action: ->(*params) { Network.show(*params) }
    },
    network_config: {
      description: 'Write host network configuration to the file',
      action: ->(*params) { ShowNetworkConfigCommand.execute(params, self, $out) }
    },
    platforms: {
      description: 'List all known platforms',
      action: ->(*) { show_platforms }
    },
    private_ip: {
      description: 'Show private ip address of the box',
      action: ->(*params) { Network.show(*params) }
    },
    provider: {
      description: 'Show provider for the specified box',
      action: ->(*params) { show_provider(*params) }
    },
    repos: {
      description: 'List all configured repositories',
      action: ->(*) { @repos.show }
    },
    versions: {
      description: 'List boxes versions for specified platform',
      action: ->(*) { show_platform_versions }
    }
  }.freeze

  # Show list of actions available for the base command
  #
  # @param base_command [String] name of the command user is typing
  # @param actions [Hash] list of commands that must be described
  def display_usage_info(base_command, actions)
    max_width = actions.keys.map(&:length).max
    $out.out "List of subcommands for #{base_command}"
    actions.keys.sort.each do |action|
      $out.out format("%-#{max_width}s %s", action, actions[action][:description])
    end
    0
  end

  # Show information to the user about
  #
  # @param parameters [Array] of parameters to the show command
  def show(parameters)
    if parameters.empty?
      $out.warning 'Please specify an action for the show command.'
      display_usage_info('show', SHOW_COMMAND_ACTIONS)
      return 0
    end
    action_name, *action_parameters = *parameters
    action = SHOW_COMMAND_ACTIONS[action_name.to_sym]
    if action.nil?
      $out.warning "Unknown action for the show command: #{action_name}."
      display_usage_info('show', SHOW_COMMAND_ACTIONS)
      return 2
    end
    instance_exec(*action_parameters, &action[:action])
  end

  def clone_config(path_to_nodes, new_path_to_nodes)
    $out.info "Performing cloning operation for config #{path_to_nodes}. Cloned configuration name: #{new_path_to_nodes}"
    Clone.new.clone_nodes(path_to_nodes, new_path_to_nodes)
    return 0
  end

  # all mdbci commands swith
  def commands
    exit_code = 1
    case ARGV.shift
    when 'check_relevance'
      exit_code = checkRelevanceNetworkConfig(ARGV.shift)
    when 'clone'
      exit_code = clone_config(ARGV[0], ARGV[1])
    when 'configure'
      command = ConfigureCommand.new(ARGV, self, $out)
      exit_code = command.execute
    when 'deploy-examples'
      command = DeployCommand.new([ARGV.shift], self, $out)
      exit_code = command.execute
    when 'destroy'
      destroy = DestroyCommand.new(ARGV, self, $out)
      exit_code = destroy.execute
    when 'generate'
      command = GenerateCommand.new(ARGV, self, $out)
      exit_code = command.execute
    when 'generate-product-repositories'
      command = GenerateProductRepositoriesCommand.new(ARGV, self, $out)
      exit_code = command.execute
    when 'help'
      command = HelpCommand.new(ARGV, self, $out)
      exit_code = command.execute
    when 'install_product'
      exit_code = NodeProduct.install_product(ARGV.shift)
    when 'public_keys'
      command = PublicKeysCommand.new(ARGV, self, $out)
      exit_code = command.execute
    when 'setup'
      exit_code = setup(ARGV.shift)
    when 'setup-dependencies'
      command = SetupDependenciesCommand.new(ARGV, self, $out)
      exit_code = command.execute()
    when 'setup_repo'
      exit_code = NodeProduct.setup_product_repo(ARGV.shift)
    when 'show'
      exit_code = show(ARGV)
    when 'snapshot'
      snapshot = SnapshotCommand.new(ARGV, self, $out)
      exit_code = snapshot.execute
    when 'ssh'
      exit_code = ssh(ARGV.shift)
    when 'sudo'
      sudo = SudoCommand.new(ARGV, self, $out)
      exit_code = sudo.execute
    when 'up'
      command = UpCommand.new([ARGV.shift], self, $out)
      exit_code = command.execute
    when 'validate_template'
      exit_code = validate_template
    else
      $out.error 'Unknown mdbci command. Please look help!'
      command = HelpCommand.new(ARGV, self, $out)
      command.execute
    end
    return exit_code
  end

  def show_provider(name=nil)
    begin
      box_definition = @box_definitions.get_box(name)
      $out.out(box_definition['provider'])
      true
    rescue ArgumentError => error
      $out.error(error.message)
      false
    end
  end

  # print boxes platform versions by platform name
  def show_platform_versions
    if @boxPlatform.nil?
      $out.warning('Please specify the platform via --platform flag.')
      return false
    end

    boxes = @box_definitions.select do |_, definition|
      definition['platform'] == @boxPlatform
    end
    if boxes.size.zero?
      $out.error("The platform #{@boxPlatform} is not supported.")
      return false
    end

    $out.info("Supported versions for #{@boxPlatform}")
    versions = boxes.map { |_, definition| definition['platform_version'] }.uniq
    $out.out(versions)
    true
  end

  def checkRelevanceNetworkConfig(filename)
    system 'scripts/check_network_config.sh ' + filename
  end

end

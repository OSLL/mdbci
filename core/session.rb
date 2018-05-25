require 'json-schema'
require 'json'
require 'fileutils'
require 'uri'
require 'open3'
require 'xdg'


require_relative 'network'
require_relative 'boxes_manager'
require_relative 'repo_manager'
require_relative 'out'
require_relative 'docker_manager'
require_relative 'helper'
require_relative 'clone'
require_relative 'commands/up_command'
require_relative 'commands/snapshot_command'
require_relative 'commands/destroy_command'
require_relative 'commands/generate_command'
require_relative 'commands/generate_product_repositories_command'
require_relative 'commands/help_command'
require_relative 'constants'

class Session

  attr_accessor :boxes
  attr_accessor :configs
  attr_accessor :configuration_file
  attr_accessor :versions
  attr_accessor :configFile
  attr_accessor :boxesFile
  attr_accessor :boxName
  attr_accessor :field
  attr_accessor :awsConfig # aws-config parameters
  attr_accessor :awsConfigFile # aws-config.yml file
  attr_accessor :awsConfigOption # path to aws-config.yml in template file
  attr_accessor :isOverride
  attr_accessor :isSilent
  attr_accessor :command
  attr_accessor :repos
  attr_accessor :repo_dir
  attr_accessor :mdbciNodes # mdbci nodes
  attr_accessor :templateNodes
  attr_accessor :nodesProvider # current configuration provider
  attr_accessor :attempts
  attr_accessor :boxes_dir
  attr_accessor :mdbciDir
  attr_accessor :mdbci_dir
  attr_accessor :maxscale_ci
  attr_accessor :starting_dir
  attr_accessor :working_dir
  attr_accessor :nodeProduct
  attr_accessor :productVersion
  attr_accessor :keyFile
  attr_accessor :keep_template
  attr_accessor :boxPlatform
  attr_accessor :boxPlatformVersion
  attr_accessor :path_to_nodes
  attr_accessor :node_name
  attr_accessor :snapshot_name
  attr_accessor :ipv6

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
    @boxes_dir = File.join(@mdbci_dir, 'BOXES') unless @boxes_dir
    @repo_dir = File.join(@mdbci_dir, 'repo.d') unless @repo_dir
  end

  # Method initializes services that depend on the parsed configuration
  def initialize_services
    fill_paths
    $out.info "Load Boxes from #{@boxes_dir}"
    @boxes = BoxesManager.new(@boxes_dir)
    $out.info "Load AWS config from #{@awsConfigFile}"
    @awsConfig = $exception_handler.handle('AWS configuration file not found') { YAML.load_file(@awsConfigFile)['aws'] }
    $out.info "Load Repos from #{@repo_dir}"
    @repos = RepoManager.new(@repo_dir)
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
    possibly_failed_command = ''
    case what
      when 'boxes'
        $out.info 'Adding boxes to vagrant'
        raise "cannot adding boxes: directory not exist" unless Dir.exists?($session.boxes_dir)
        raise "cannot adding boxes: boxes are not found in #{$session.boxes_dir}" unless File.directory?($session.boxes_dir)
        @boxes.boxesManager.each do |key, value|
          next if value['provider'] == "aws" # skip 'aws' block
          # TODO: add aws dummy box
          # vagrant box add dummy https://github.com/mitchellh/vagrant-aws/raw/master/dummy.box

          next if value['provider'] == "mdbci" # skip 'mdbci' block
          if value['box'].to_s =~ URI::regexp # THERE CAN BE DONE CUSTOM EXCEPTION
            puts 'vagrant box add '+key.to_s+' '+value['box'].to_s
            shell = 'vagrant box add '+key.to_s+' '+value['box'].to_s
          else
            puts "vagrant box add --provider #{value['provider']} "+value['box'].to_s
            shell = "vagrant box add --provider #{value['provider']} "+value['box'].to_s
          end
          shellCommand = `#{shell} 2>&1` # THERE CAN BE DONE CUSTOM EXCEPTION

          puts "#{shellCommand}\n"
          # just one soft exeption - box already exist
          if $?!=0 && shellCommand[/attempting to add already exists/]==nil
            raise "failed command: #{shell}"
          end
        end
      else
        raise "Cannot setup #{what}"
    end

    return 0
  end

  def sudo(args)
    raise 'config name is required' if args.nil?
    config = args.split('/')
    raise 'config does not exists' unless Dir.exist?(config[0])
    raise 'node name is required' if config[1].to_s.empty?
    pwd = Dir.pwd
    Dir.chdir config[0]
    cmd = 'vagrant ssh '+config[1]+' -c "/usr/bin/sudo '+$session.command+'"'
    $out.info 'Running ['+cmd+'] on '+config[0]+'/'+config[1]
    vagrant_out = `#{cmd}`
    exit_code = $?.exitstatus
    $out.out vagrant_out
    Dir.chdir pwd
    if exit_code != 0
      raise "command '#{cmd}' exit with non-zero code: #{exit_code}"
    end
    return 0
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

    box_params = $session.boxes.getBox(box)
    cmd = 'ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ' + $mdbci_exec_dir.to_s+'/KEYS/'+box_params['keyfile'].to_s + " "\
                    + box_params['user'].to_s + "@"\
                    + box_params['IP'].to_s + " "\
                    + "'" + $session.command + "'"
    return cmd
  end

  def runSSH(cmd,params)
    dir = params[0]
    node_arg =  params[1]
    $out.info 'Running ['+cmd+'] on '+dir.to_s+'/'+node_arg.to_s
    vagrant_out = `#{cmd}`
    if $?.exitstatus!=0
     $out.out vagrant_out
     raise "'#{cmd}' command returned non-zero exit code: (#{$?.exitstatus})"
    end
    return vagrant_out.to_s
  end

  def platformKey(box_name)
    key = $session.boxes.boxesManager.keys.select { |value| value == box_name }
    return key.nil? ? "UNKNOWN" : $session.boxes.boxesManager[key[0]]['platform']+'^'+$session.boxes.boxesManager[key[0]]['platform_version']
  end


  def showBoxKeys
    values = Array.new
    $session.boxes.boxesManager.values.each do |value|
      values.push value[$session.field] if value[$session.field]
    end
    if values.empty?
      raise "box key #{$session.field} is not found"
    end
    puts values.uniq
    return 0
  end

  def getPlatfroms
    if !@boxes.boxesManager.empty?
      platforms = Array.new
      @boxes.boxesManager.each do |box|
        platforms.push box[1][PLATFORM]
      end
      platforms.uniq
    else
      raise 'Boxes are not found'
    end
  end

  def showPlatforms
    exit_code = 1
    begin
      $out.out @boxes.boxesManager.keys
      exit_code = 0
    rescue
      $out.error "check boxes configuration and try again"
      exit_code = 1
    end
    $out.out getPlatfroms
    return exit_code
  end

  # show boxes with platform and version
  def showBoxes
    if @boxPlatform.nil?
      $out.warning 'Required parameter --platform is not defined.'
      $out.info 'Full command specification:'
      $out.info './mdbci show boxes --platform PLATFORM [--platform-version VERSION]'
      return 1
    end
    # check for undefined box platform
    some_box = @boxes.boxesManager.find { |box| box[1]['platform'] == @boxPlatform }
    if some_box.nil?
      $out.warning "Platform #{@boxPlatform} is not supported!"
      return 1
    end
    if @boxPlatformVersion.nil?
      $out.warning 'Optional paremeter --platform-version is not defined'
    end

    platform_name = if @boxPlatformVersion.nil?
                      @boxPlatform
                    else
                      "#{@boxPlatform}^#{@boxPlatformVersion}"
                    end
    $out.info "List of boxes for the #{platform_name} platform:"
    boxes_found = false
    @boxes.boxesManager.each do |box, params|
      if params['platform'] == @boxPlatform && (
           @boxPlatformVersion.nil? || params['platform_version'] == @boxPlatformVersion)
        $out.out box
        boxes_found = true
      end
    end
    boxes_found ? 0 : 1
  end

  def showBoxField
    $out.out findBoxField($session.boxName, $session.field)
    return 0
  end

  def findBoxField(boxName, field)
    box = $session.boxes.getBox(boxName)
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


  def showBoxNameByPath(path = nil)
    if path.nil?
      $out.warning 'Please specify the path to the nodes configuration as a parameter'
      return 2
    end
    boxName = $session.boxes.getBoxNameByPath(path)
    $out.out boxName
    0
  end

  def validate_template
    raise 'Template must be specified!' unless $session.configFile
    begin
      schema = JSON.parse(File.read 'templates/schemas/template.json')
      json = JSON.parse(File.read $session.configFile)
      JSON::Validator.validate!(schema, json)
      $out.info "Template #{$session.configFile} is valid"
    rescue JSON::Schema::ValidationError => e
      $out.error "Template #{$session.configFile} is NOT valid"
      raise e.message
    end
    return 0
  end

  # List of actions that are provided by the show command.
  SHOW_COMMAND_ACTIONS = {
    box: {
      description: 'Show box name based on the path to the configuration file',
      action: ->(*params) { showBoxNameByPath(*params) }
    },
    boxes: {
      description: 'List available boxes',
      action: ->(*) { showBoxes }
    },
    boxinfo: {
      description: 'Show the field value of the box configuration',
      action: ->(*) { showBoxField }
    },
    boxkeys: {
      description: 'Show keys for all configured boxes',
      action: ->(*) { showBoxKeys }
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
      action: ->(*params) { printConfigurationNetworkInfoToFile(*params) }
    },
    platforms: {
      description: 'List all known platforms',
      action: ->(*) { showPlatforms }
    },
    private_ip: {
      description: 'Show private ip address of the box',
      action: ->(*params) { Network.show(*params) }
    },
    provider: {
      description: 'Show provider for the specified box',
      action: ->(*params) { showProvider(*params) }
    },
    repos: {
      description: 'List all configured repositories',
      action: ->(*) { @repos.show }
    },
    versions: {
      description: 'List boxes versions for specified platform',
      action: ->(*) { showBoxesPlatformVersions }
    }
  }

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

  def clone(path_to_nodes, new_path_to_nodes)
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
      exit_code = clone(ARGV[0], ARGV[1])
    when 'destroy'
      destroy = DestroyCommand.new(ARGV, self, $out)
      exit_code = destroy.execute
    when 'generate'
      exit_code = generate(ARGV.shift)
    when 'generate-product-repositories'
      command = GenerateProductRepositoriesCommand.new(ARGV, self, $out)
      exit_code = command.execute
    when 'help'
      command = HelpCommand.new(ARGV, self, $out)
      exit_code = command.execute
    when 'install_product'
      exit_code = NodeProduct.installProduct(ARGV.shift)
    when 'public_keys'
      exit_code = publicKeys(ARGV.shift)
    when 'setup'
      exit_code = setup(ARGV.shift)
    when 'setup_repo'
      exit_code = NodeProduct.setupProductRepo(ARGV.shift)
    when 'show'
      exit_code = show(ARGV)
    when 'snapshot'
      snapshot = SnapshotCommand.new(ARGV, self, $out)
      exit_code = snapshot.execute
    when 'ssh'
      exit_code = ssh(ARGV.shift)
    when 'sudo'
      exit_code = sudo(ARGV.shift)
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

  # load mdbci boxes parameters from boxes.json
  def LoadNodesProvider(configs)
    nodes = {}
    configs.keys.each do |node|
      nodes[node] = configs[node] if node != "aws_config" and node != "cookbook_path"
    end
    nodes.values.each do |node|
      puts node
      box = node['box'].to_s
      raise "box in " + node.to_s + " is not found" if box.empty?
      box_params = @boxes.getBox(box)
      raise "Box #{box} from node #{node[0]} not found in #{$session.boxes_dir}!" if box_params.nil?
      @nodesProvider = box_params["provider"].to_s
    end
  end

  def generate(name)
    if name.nil?
      path = "#{Dir.pwd}/default"
    else
      path = File.absolute_path(name.to_s)
    end
    #
    # TODO: ExceptionHandler need to be refactored! Don't return 1 for error
    begin
      IO.read($session.configFile)
    rescue
      raise 'Instance configuration file not found!'
    end
    instanceConfigFile = $exception_handler.handle('INSTANCE configuration file not found') { IO.read($session.configFile) }
    if instanceConfigFile.nil?
      raise 'Instance configuration file invalid!'
    end
    @configs = $exception_handler.handle('INSTANCE configuration file invalid') { JSON.parse(instanceConfigFile) }
    raise 'Template configuration file is empty!' if @configs.nil?

    LoadNodesProvider configs
    #
    aws_config = @configs.find { |value| value.to_s.match(/aws_config/) }
    @awsConfigOption = aws_config.to_s.empty? ? $mdbci_exec_dir+'/aws-config.yml' : aws_config[1].to_s
    #
    if @nodesProvider != 'mdbci'
      GenerateCommand.generate(path, configs, boxes, isOverride, nodesProvider)
      $out.info 'Generating config in ' + path
    else
      $out.info 'Using mdbci ppc64 box definition, generating config in ' + path + '/mdbci_template'
      # TODO: dir already exist?
      Dir.mkdir path unless File.exists? path
      mdbci = File.new(path+'/mdbci_template', 'w')
      mdbci.print $session.configFile
      mdbci.close
    end
    # write nodes provider and template to configuration nodes dir file
    provider_file = path+'/provider'
    if !File.exist?(provider_file)
      File.open(path+'/provider', 'w') { |f| f.write(@nodesProvider.to_s) }
    else
      raise 'Configuration \'provider\' template file don\'t exist'
    end
    if @nodesProvider != 'mdbci'
      template_file = path+'/template'
      if !File.exist?(template_file)
        File.open(path+'/template', 'w') { |f| f.write(File.expand_path configFile) }
      else
        raise 'Configuration \'template\' file don\'t exist'
      end
    end

    return 0
  end

  # copy ssh keys to config/node
  def publicKeys(args)
    pwd = Dir.pwd

    raise 'Configuration name is required' if args.nil?

    args = args.split('/')

    # mdbci box
    if File.exist?(args[0]+'/mdbci_template')
      loadMdbciNodes args[0]
      if args[1].nil? # read ip for all nodes
        if $session.mdbciNodes.empty?
          raise "MDBCI nodes not found in #{args[0]}"
        end
        $session.mdbciNodes.each do |node|
          box = node[1]['box'].to_s
          raise "Box empty in node: #{node}" unless !box.empty?
          mdbci_params = $session.boxes.getBox(box)
          #
          keyfile_content = $exception_handler.handle("Keyfile not found! Check keyfile path!") { File.read(@keyFile) }
          # add keyfile_content to the end of the authorized_keys file in ~/.ssh directory
          command = 'echo \''+keyfile_content+'\' >> /home/'+mdbci_params['user']+'/.ssh/authorized_keys'
          cmd = 'ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ' + $mdbci_exec_dir.to_s+'/KEYS/'+mdbci_params['keyfile'].to_s + " "\
                          + mdbci_params['user'].to_s + "@" + mdbci_params['IP'].to_s + " "\
                          + "\"" + command + "\""
          $out.info 'Copy '+@keyFile.to_s+' to '+node[0].to_s
          $out.info `#{cmd}`
          if $?.exitstatus!=0
            raise "command #{cmd} exit with non-zero code: #{$?.exitstatus}"
          end
        end
      else
        mdbci_node = @mdbciNodes.find { |elem| elem[0].to_s == args[1] }

        if mdbci_node.nil?
          raise "No such node with name #{args[1]} in #{args[0]}"
        end

        box = mdbci_node[1]['box'].to_s
        if !box.empty?
          mdbci_params = $session.boxes.getBox(box)
          #
          keyfile_content = $exception_handler.handle("Keyfile not found! Check keyfile path!") { File.read(@keyFile) }
          # add to the end of the authorized_keys file in ~/.ssh directory
          command = 'echo \''+keyfile_content+'\' >> /home/'+mdbci_params['user']+'/.ssh/authorized_keys'
          cmd = 'ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ' + $mdbci_exec_dir.to_s+'/KEYS/'+mdbci_params['keyfile'].to_s + " "\
                          + mdbci_params['user'].to_s + "@" + mdbci_params['IP'].to_s + " "\
                          + "\"" + command + "\""
          $out.info 'Copy '+@keyFile.to_s+' to '+mdbci_node[0].to_s
          $out.info `#{cmd}`

          if $?.exitstatus != 0
            raise "command #{cmd} exit with non-zero code: #{$?.exitstatus}"
          end
        else
          raise "Wrong box parameter in node: #{args[1]}"
        end
      end
    else # aws, vbox, libvirt, docker nodes

      unless Dir.exists? args[0]
        raise "Directory with nodes does not exists: #{args[0]}"
      end

      network = Network.new
      network.loadNodes args[0] # load nodes from dir

      if network.nodes.empty?
        raise "No aws, vbox, libvirt, docker nodes found in #{args[0]}"
      end

      if args[1].nil? # No node argument, copy keys to all nodes
        network.nodes.each do |node|
          keyfile_content = $exception_handler.handle("Keyfile not found! Check path to it!") { File.read(@keyFile) }
          # add keyfile content to the end of the authorized_keys file in ~/.ssh directory
          cmd = 'vagrant ssh '+node.name.to_s+' -c "echo \''+keyfile_content+'\' >> ~/.ssh/authorized_keys"'
          $out.info 'Copy '+@keyFile.to_s+' to '+node.name.to_s+'.'
          $out.info `#{cmd}`
          if $?.exitstatus!=0
            raise "command #{cmd} exit with non-zero code: #{$?.exitstatus}"
          end
        end
      else
        node = network.nodes.find { |elem| elem.name == args[1] }

        if node.nil?
          raise "No such node with name #{args[1]} in #{args[0]}"
        end

        #
        keyfile_content = $exception_handler.handle("Keyfile not found! Check path to it!") { File.read(@keyFile) }
        # add keyfile content to the end of the authorized_keys file in ~/.ssh directory
        cmd = 'vagrant ssh '+node.name.to_s+' -c "echo \''+keyfile_content+'\' >> ~/.ssh/authorized_keys"'
        $out.info 'Copy '+@keyFile.to_s+' to '+node.name.to_s+'.'
        $out.info `#{cmd}`
        if $?.exitstatus!=0
          raise "command #{cmd} exit with non-zero code: #{$?.exitstatus}"
        end
      end
    end

    Dir.chdir pwd
  end

  def showProvider(name=nil)
    exit_code = 1
    if $session.boxes.boxesManager.has_key?(name)
      box_params = $session.boxes.getBox(name)
      provider = box_params["provider"].to_s
      $out.out provider
      exit_code = 0
    else
      exit_code = 1
      $out.warning name.to_s+" box does not exist! Please, check box name!"
    end
    return exit_code
  end

  # print boxes platform versions by platform name
  def showBoxesPlatformVersions
    exit_code = 0
    if $session.boxPlatform == nil
      raise "Specify parameter --platforms and try again"
    end

    # check for supported platforms
    some_platform = $session.boxes.boxesManager.find { |box| box[1]['platform'] == $session.boxPlatform }
    if some_platform.nil?
      raise "Platform #{$session.boxPlatform} is not supported!"
    end

    $out.info "Supported versions for #{$session.boxPlatform}:"

    boxes_versions = getBoxesPlatformVersions($session.boxPlatform, $session.boxes.boxesManager)

    # output platforms versions
    boxes_versions.each { |version| $out.out version }
    return exit_code
  end

  def getBoxesPlatformVersions(boxPlatform, boxesManager)
    boxes_versions = Array.new
    # get boxes platform versions
    boxesManager.each do |box, params|
      next if params['platform'] != boxPlatform # skip unknown platform
      if !(params.has_value?(boxPlatform))
        raise "#{boxPlatform} has 0 supported versions! Please check box platform!"
      end
      box_platform_version = params['platform_version']
      boxes_versions.push(box_platform_version)
    end

    boxes_versions = boxes_versions.uniq # delete duplicates values
    return boxes_versions
  end

  # load node platform by name
  def loadNodePlatform(name)
    pwd = Dir.pwd
    # template file
    templateFile = $exception_handler.handle('Template nodes file not found') { IO.read(pwd.to_s+'/template') }
    templateNodes = $exception_handler.handle('Template configuration file invalid') { JSON.parse(IO.read(templateFile)) }
    #
    node = templateNodes.find { |elem| elem[0].to_s == name }
    box = node[1]['box'].to_s
    if $session.boxes.boxesManager.has_key?(box)
      box_params = $session.boxes.getBox(box)
      platform = box_params[PLATFORM].to_s+'^'+box_params['platform_version'].to_s
      return platform
    else
      $out.warning name.to_s+" platform does not exist! Please, check box name!"
    end

  end

  def checkRelevanceNetworkConfig(filename)
    system 'scripts/check_network_config.sh ' + filename
  end

end

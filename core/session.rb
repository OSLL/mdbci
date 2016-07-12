require 'json-schema'
require 'json'
require 'fileutils'
require 'uri'
require 'open3'

require_relative 'generator'
require_relative 'network'
require_relative 'boxes_manager'
require_relative 'repo_manager'
require_relative 'out'
require_relative 'docker_manager'
require_relative 'snapshot'
require_relative 'helper'


class Session

  attr_accessor :boxes
  attr_accessor :configs
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
  attr_accessor :repoDir
  attr_accessor :mdbciNodes # mdbci nodes
  attr_accessor :templateNodes
  attr_accessor :nodesProvider # current configuration provider
  attr_accessor :attempts
  attr_accessor :boxesDir
  attr_accessor :mdbciDir
  attr_accessor :nodeProduct
  attr_accessor :productVersion
  attr_accessor :keyFile
  attr_accessor :boxPlatform
  attr_accessor :boxPlatformVersion
  attr_accessor :path_to_nodes
  attr_accessor :node_name
  attr_accessor :snapshot_name

  PLATFORM = 'platform'
  VAGRANT_NO_PARALLEL = '--no-parallel'

  CHEF_NOT_FOUND_ERROR = <<EOF
The chef binary (either `chef-solo` or `chef-client`) was not found on
the VM and is required for chef provisioning. Please verify that chef
is installed and that the binary is available on the PATH.
EOF

  OUTPUT_NODE_NAME_REGEX = "==>\s+(.*):{1}"
  DOCKER = 'docker'
  LIBVIRT = 'libvirt'

  def initialize
    @boxesDir = './BOXES'
    @repoDir = './repo.d'
    @mdbciNodes = Hash.new
    @templateNodes = Hash.new
  end

=begin
     Load collections from json files:
      - boxes.json
      - template.json
      - aws-config.yml
      - versions.json
=end

  def loadCollections

    @mdbciDir = Dir.pwd

    $out.info 'Load Boxes from '+$session.boxesDir
    @boxes = BoxesManager.new($session.boxesDir)

    $out.info 'Load AWS config from ' + @awsConfigFile
    @awsConfig = $exception_handler.handle('AWS configuration file not found') { YAML.load_file(@awsConfigFile)['aws'] }

    $out.info 'Load Repos from '+$session.repoDir
    @repos = RepoManager.new($session.repoDir)

  end

  def setup(what)
    possibly_failed_command = ''
    case what
      when 'boxes'
        $out.info 'Adding boxes to vagrant'
        raise "cannot adding boxes: directory not exist" unless Dir.exists?($session.boxesDir)
        raise "cannot adding boxes: boxes are not found in #{$session.boxesDir}" unless File.directory?($session.boxesDir)
        @boxes.boxesManager.each do |key, value|
          next if value['provider'] == "aws" # skip 'aws' block
          # TODO: add aws dummy box
          # vagrant box add dummy https://github.com/mitchellh/vagrant-aws/raw/master/dummy.box

          next if value['provider'] == "mdbci" # skip 'mdbci' block
          if value['box'].to_s =~ URI::regexp # THERE CAN BE DONE CUSTOM EXCEPTION
            puts 'vagrant box add '+key.to_s+' '+value['box'].to_s
            shell = 'vagrant box add '+key.to_s+' '+value['box'].to_s
          else
            puts 'vagrant box add --provider virtualbox '+value['box'].to_s
            shell = 'vagrant box add --provider virtualbox '+value['box'].to_s
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

  def checkConfig
    #TODO #6267
    $out.info 'Checking this machine configuration requirments'
    $out.info '.....NOT IMPLEMENTED YET'
  end

  def sudo(args)
    exit_code = 1
    possibly_failed_command = ''
    pwd = Dir.pwd

    if args.nil?
      $out.error 'Configuration name is required'
      exit_code = 1
    end

    config = args.split('/')
    unless Dir.exists?(config[0])
      $out.error 'Machine with such name does not exists'
      exit_code = 1
    end

    Dir.chdir config[0]
    cmd = 'vagrant ssh '+config[1]+' -c "/usr/bin/sudo '+$session.command+'"'
    $out.info 'Running ['+cmd+'] on '+config[0]+'/'+config[1]
    vagrant_out = `#{cmd}`
    exit_code = $?.exitstatus
    possibly_failed_command = cmd
    $out.out vagrant_out

    Dir.chdir pwd

    if exit_code != 0
      $out.error "command '#{possibly_failed_command}' exit with non-zero code: #{exit_code}"
      exit_code = 1
    end

    return exit_code
  end

  # load template nodes
  def loadTemplateNodes()
    pwd = Dir.pwd
    instanceFile = $exception_handler.handle('INSTANCE configuration file not found') { IO.read(pwd+'/template') }
    $out.info 'Load nodes from template file ' + instanceFile.to_s
    @templateNodes = $exception_handler.handle('INSTANCE configuration file invalid') { JSON.parse(IO.read(@mdbciDir+'/'+instanceFile)) }
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
    exit_code = 1
    possibly_failed_command = ''
    pwd = Dir.pwd

    if args.nil?
      $out.error 'Configuration name is required'
      exit_code = 1
    end

    params = args.split('/')
    # mdbci ppc64 boxes
    if File.exist?(params[0]+'/mdbci_template')
      loadMdbciNodes params[0]
      if params[1].nil? # ssh for all nodes
        @mdbciNodes.each do |node|
          box = node[1]['box'].to_s
          raise "box in " + node[1].to_s + " is not found" if box.empty?
          mdbci_box_params = $session.boxes.getBox(box)
          cmd = 'ssh -i ' + pwd.to_s+'/KEYS/'+mdbci_box_params['keyfile'].to_s + " "\
                          + mdbci_box_params['user'].to_s + "@"\
                          + mdbci_box_params['IP'].to_s + " "\
                          + "'" + $session.command + "'"
          $out.info 'Running ['+cmd+'] on '+params[0].to_s+'/'+params[1].to_s
          vagrant_out = `#{cmd}`
          exit_code = $?.exitstatus
          possibly_failed_command = cmd
          $out.out vagrant_out
        end
      else
        mdbci_node = @mdbciNodes.find { |elem| elem[0].to_s == params[1] }
        box = mdbci_node[1]['box'].to_s
        raise "box in " + mdbci_node[1].to_s + " is not found" if box.empty?
        mdbci_params = $session.boxes.getBox(box)
        cmd = 'ssh -i ' + pwd.to_s+'/KEYS/'+mdbci_params['keyfile'].to_s + " "\
                        + mdbci_params['user'].to_s + "@"\
                        + mdbci_params['IP'].to_s + " "\
                        + "'" + $session.command + "'"
        $out.info 'Running ['+cmd+'] on '+params[0].to_s+'/'+params[1].to_s
        vagrant_out = `#{cmd}`
        exit_code = $?.exitstatus
        possibly_failed_command = cmd
        $out.out vagrant_out
      end
    else # aws, vbox nodes
      unless Dir.exist?(params[0])
        $out.error 'Machine with such name does not exist'
        exit_code = 1
      end
      Dir.chdir params[0]
      cmd = 'vagrant ssh '+params[1].to_s+' -c "'+$session.command+'"'
      $out.info 'Running ['+cmd+'] on '+params[0].to_s+'/'+params[1].to_s
      vagrant_out = `#{cmd}`
      exit_code = $?.exitstatus
      possibly_failed_command = cmd
      $out.out vagrant_out
      Dir.chdir pwd
    end

    if exit_code != 0
      $out.error "'ssh' (or 'vagrant ssh') command returned non-zero exit code: (#{$?.exitstatus})"
      $out.error "failed ssh command: #{possibly_failed_command}"
      exit_code = 1
    end

    return exit_code
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

  def showBoxes
    exit_code = 1
    begin
      $out.out JSON.pretty_generate(@boxes.boxesManager)
      exit_code = 0
    rescue
      $out.error "check boxes configuration and try again"
      exit_code = 1
    end
    return exit_code
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
    exit_code = 1

    if $session.boxPlatform.nil?
      $out.warning './mdbci show boxes --platform command option is not defined!'
      exit_code = 1
    elsif $session.boxPlatform.nil? and $session.boxPlatformVersion.nil?
      $out.warning './mdbci show boxes --platform or --platform-version command parameters are not defined!'
      exit_code = 1
    end
    # check for undefined box
    some_box = $session.boxes.boxesManager.find { |box| box[1]['platform'] == $session.boxPlatform }
    if some_box.nil?
      $out.warning 'Platform '+$session.boxPlatform+' is not supported!'
      exit_code = 1
    end

    if !$session.boxPlatformVersion.nil?
      $out.info 'List of boxes for the '+$session.boxPlatform+'^'+$session.boxPlatformVersion+' platform'
    else
      $out.info 'List of boxes for the '+$session.boxPlatform+' platform:'
    end
    $session.boxes.boxesManager.each do |box, params|
      if params.has_value?($session.boxPlatform) and $session.boxPlatformVersion.nil?
        $out.out box.to_s
        exit_code = 0
      elsif params.has_value?($session.boxPlatform) and params.has_value?($session.boxPlatformVersion)
        $out.out box.to_s
        exit_code = 0
      end
    end

    return exit_code
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


  def showBoxNameByPath(path)
    boxName = $session.boxes.getBoxNameByPath(path)
    $out.out boxName
    return 0
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


  def show(collection)
    exit_code = 1
    case collection
      when 'boxes'
        exit_code = showBoxes
      when 'box'
        exit_code = showBoxNameByPath(ARGV.shift)
      when 'boxinfo'
        exit_code = showBoxField
      when 'repos'
        @repos.show
      when 'versions'
        exit_code = showBoxesPlatformVersions
      when 'platforms'
        exit_code = showPlatforms
      when 'network'
        exit_code = Network.show(ARGV.shift)
      when 'private_ip'
        exit_code = Network.private_ip(ARGV.shift)
      when 'keyfile'
        exit_code = Network.showKeyFile(ARGV.shift)
      when 'boxkeys'
        exit_code = showBoxKeys
      when 'provider'
        exit_code = showProvider(ARGV.shift)
      else
        $out.error 'Unknown show command collection: '+collection
    end
    return exit_code
  end


  def clone(configuration, new_path)
    $out.info "Performing cloning operation for config #{configuration}. Cloned configuration name: #{new_path}"
    cloneNodes(configuration, new_path)
    return 0
  end


  # all mdbci commands swith
  def commands
    exit_code = 1
    case ARGV.shift
      when 'show'
        exit_code = $session.show(ARGV.shift)
      when 'sudo'
        exit_code = $session.sudo(ARGV.shift)
      when 'ssh'
        exit_code = $session.ssh(ARGV.shift)
      when 'setup'
        exit_code = $session.setup(ARGV.shift)
      when 'generate'
        exit_code = $session.generate(ARGV.shift)
      when 'up'
        exit_code = $session.up(ARGV.shift)
      when 'setup_repo'
        exit_code = NodeProduct.setupProductRepo(ARGV.shift)
      when 'install_product'
        exit_code = NodeProduct.installProduct(ARGV.shift)
      when 'public_keys'
        exit_code = $session.publicKeys(ARGV.shift)
      when 'validate_template'
        exit_code = $session.validate_template
      when 'snapshot'
        snapshot = Snapshot.new
        exit_code = snapshot.do(ARGV.shift)
      when 'clone'
        exit_code = $session.clone(ARGV[0], ARGV[1])
      else
        $out.error 'Unknown mdbci command. Please look help!'
        Help.display
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
      raise "Box #{box} from node #{node[0]} not found in #{$session.boxesDir}!" if box_params.nil?
      @nodesProvider = box_params["provider"].to_s
    end
  end

  def generate(name)
    path = Dir.pwd

    if name.nil?
      path += '/default'
    else
      path +='/'+name.to_s
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
    @awsConfigOption = aws_config.to_s.empty? ? '' : aws_config[1].to_s
    #
    if @nodesProvider != 'mdbci'
      Generator.generate(path, configs, boxes, isOverride, nodesProvider)
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
        File.open(path+'/template', 'w') { |f| f.write(configFile.to_s) }
      else
        raise 'Configuration \'template\' file don\'t exist'
      end
    end

    return 0
  end

  def generateDockerImages(config, nodes_directory)
    $out.info 'Generating docker images...'
    config.each do |node|
      unless node[1]['box'].nil?
        DockerManager.build_image("#{nodes_directory}/#{node[0]}", node[1]['box'])
      end
    end
  end

  # Deploy configurations
  def up(args)
    std_q_attampts = 5

    # No arguments provided
    raise "Command 'up' needs one argument, found zero" if args.nil?

    # No attempts provided
    if @attempts.nil?
      @attempts = std_q_attampts
    else
      @attempts = @attempts.to_i
    end

    # Saving dir, do then to change it back
    pwd = Dir.pwd

    # Separating config_path from node
    config = []
    node = ''
    up_type = false # Means no node specified
    paths = args.split('/') # Get array of dirs
    # Get path to vagrant instance directory
    config_path = paths[0, paths.length - 1].join('/')
    if !config_path.empty?
      # So there may be node specified
      node = paths[paths.length - 1]
      config[0] = config_path
      config[1] = node
      up_type = true # Node specified
    end

    # Checking if vagrant instance derictory exists
    if Dir.exist?(config[0].to_s) # to_s in case of 'nil'
      up_type = true # node specified
      $out.info 'Node is specified ' + config[1] + ' in ' + config[0]
    else
      up_type = false # node not specified
      $out.info 'Node isn\'t specified in ' + args
    end

    template = JSON.parse(File.read(File.read "#{up_type ? config[0] : args}/template"))

    up_type ? Dir.chdir(config[0]) : Dir.chdir(args)

    # Setting provider: VBox, AWS, Libvirt, Docker
    begin
      @nodesProvider = File.read('provider')
    rescue
      raise 'File with provider info not found'
    end

    $out.info 'Current provider: ' + @nodesProvider

    if @nodesProvider == 'mdbci'
      $out.warning 'You are using mdbci nodes template. ./mdbci up command doesn\'t supported for this boxes!'
      return 1
    else
      # Generating docker images (so it will not be loaded for similar nodes repeatedly)
      generateDockerImages(template, '.') if @nodesProvider == 'docker'

      no_parallel_flag = ''
      if @nodesProvider == 'aws' or @nodesProvider == 'docker'
        no_parallel_flag = " #{VAGRANT_NO_PARALLEL} "
      end

      $out.info "Bringing up #{(up_type ? 'node ' : 'configuration ')} #{args}"

      $out.info 'Destroying everything'
      cmd_destr = 'vagrant destroy --force ' + (up_type ? config[1] : '')
      exec_cmd_destr = `#{cmd_destr}`
      $out.info exec_cmd_destr

      cmd_up = "vagrant up #{no_parallel_flag} --provider=#{@nodesProvider} #{(up_type ? config[1] : '')}"
      $out.info "Actual command: #{cmd_up}"
      chef_not_found_node = nil
      status = nil
      begin
        chef_not_found_node = nil
        status = Open3.popen3(cmd_up) do |stdin, stdout, stderr, wthr|
          stdin.close
          stdout.each_line do |line|
            $out.info line
            chef_not_found_node = line if @nodesProvider == 'aws'
          end
          stdout.close
          error = stderr.read
          stderr.close
          if @nodesProvider == 'aws' and error.to_s.include? CHEF_NOT_FOUND_ERROR
            chef_not_found_node = chef_not_found_node.to_s.match(OUTPUT_NODE_NAME_REGEX).captures[0]
          else
            error.each_line { |line| $out.error line }
            chef_not_found_node = nil
          end
          wthr.value
        end
        if chef_not_found_node
          $out.warning "Chef not is found on aws node: #{chef_not_found_node}, applying quick fix..."
          cmd_provision = "vagrant provision #{chef_not_found_node}"
          status = Open3.popen3(cmd_provision) do |stdin, stdout, stderr, wthr|
            stdin.close
            stdout.each_line { |line| $out.info line }
            stdout.close
            stderr.each_line { |line| $out.error line }
            stderr.close
            wthr.value
          end
        end
      end while chef_not_found_node != nil
      unless status.success?
        $out.error 'Bringing up failed'
        exit_code = status.exitstatus
        $out.error "exit code #{exit_code}"

        dead_machines = Array.new
        machines_with_broken_chef = Array.new

        vagrant_status = `vagrant status`.split("\n\n")[1].split("\n")
        nodes = Array.new
        vagrant_status.each { |stat| nodes.push(stat.split(/\s+/)[0]) }

        $out.warning 'Checking for dead machines and checking Chef runs on machines'
        nodes.each do |machine_name|
          status = `vagrant status #{machine_name}`.split("\n")[2]
          $out.info status
          unless status.include? 'running'
            dead_machines.push(machine_name)
            next
          end

          chef_log_cmd = "vagrant ssh #{machine_name} -c \"test -e /var/chef/cache/chef-stacktrace.out && printf 'FOUND' || printf 'NOT_FOUND'\""
          chef_log_out = `#{chef_log_cmd}`
          machines_with_broken_chef.push machine_name if chef_log_out == 'FOUND'
        end

        unless dead_machines.empty?
          $out.error 'Some machines are dead:'
          dead_machines.each { |machine| $out.error "\t#{machine}" }
        end

        unless machines_with_broken_chef.empty?
          $out.error 'Some machines have broken Chef run:'
          machines_with_broken_chef.each { |machine| $out.error "\t#{machine}" }
        end

        unless dead_machines.empty?
          (1..@attempts).each do |i|
            $out.info 'Trying to force restart broken machines'
            $out.info "Attempt: #{i}"
            dead_machines.delete_if do |machine|
              puts `vagrant destroy -f #{machine}`
              cmd_up = "vagrant up #{no_parallel_flag} --provider=#{@nodesProvider} #{machine}"
              success = Open3.popen3(cmd_up) do |stdin, stdout, stderr, wthr|
                stdout.each_line { |line| $out.info line }
                stderr.each_line { |line| $out.error line }
                wthr.value.success?
              end
              success
            end
            if !dead_machines.empty?
              $out.error 'Some machines are still dead:'
              dead_machines.each { |machine| $out.error "\t#{machine}" }
            else
              $out.info "All dead machines successfuly resurrected"
              break
            end
          end
          raise 'Bringing up failed (error description is above)' unless dead_machines.empty?
        end

        unless machines_with_broken_chef.empty?
          $out.info 'Trying to re-provision machines'
          machines_with_broken_chef.delete_if do |machine|
            cmd_up = "vagrant provision #{machine}"
            success = Open3.popen3(cmd_up) do |stdin, stdout, stderr, wthr|
              stdout.each_line { |line| $out.info line }
              stderr.each_line { |line| $out.error line }
              wthr.value.success?
            end
            success
          end
          unless machines_with_broken_chef.empty?
            $out.error 'Some machines are still have broken Chef run:'
            machines_with_broken_chef.each { |machine| $out.error "\t#{machine}" }
            (1.. @attempts).each do |i|
              $out.info 'Trying to force restart machines'
              $out.info "Attempt: #{i}"
              machines_with_broken_chef.delete_if do |machine|
                puts `vagrant destroy -f #{machine}`
                cmd_up = "vagrant up #{no_parallel_flag} --provider=#{@nodesProvider} #{machine}"
                success = Open3.popen3(cmd_up) do |stdin, stdout, stderr, wthr|
                  stdout.each_line { |line| $out.info line }
                  stderr.each_line { |line| $out.error line }
                  wthr.value.success?
                end
                success
              end
              if !machines_with_broken_chef.empty?
                $out.error 'Some machines are still have broken Chef run:'
                machines_with_broken_chef.each { |machine| $out.error "\t#{machine}" }
              else
                $out.info "All broken_chef machines successfuly reprovisioned."
                break
              end
            end
            raise 'Bringing up failed (error description is above)' unless machines_with_broken_chef.empty?
          end
        end
      end
    end
    $out.info 'All nodes successfully up!'
    Dir.chdir pwd
    $out.info "Generating #{config_path}_network_settings file"
    printConfigurationNetworkInfoToFile(config_path) 
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
          keyfile_content = $exception_handler.handle("Keyfile not found! Check keyfile path!") { File.read(pwd.to_s+'/'+@keyFile.to_s) }
          # add keyfile_content to the end of the authorized_keys file in ~/.ssh directory
          command = 'echo \''+keyfile_content+'\' >> /home/'+mdbci_params['user']+'/.ssh/authorized_keys'
          cmd = 'ssh -i ' + pwd.to_s+'/KEYS/'+mdbci_params['keyfile'].to_s + " "\
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
          keyfile_content = $exception_handler.handle("Keyfile not found! Check keyfile path!") { File.read(pwd.to_s+'/'+@keyFile.to_s) }
          # add to the end of the authorized_keys file in ~/.ssh directory
          command = 'echo \''+keyfile_content+'\' >> /home/'+mdbci_params['user']+'/.ssh/authorized_keys'
          cmd = 'ssh -i ' + pwd.to_s+'/KEYS/'+mdbci_params['keyfile'].to_s + " "\
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
        raise "Directory with nodes does not exists: #{args[1]}"
      end

      network = Network.new
      network.loadNodes args[0] # load nodes from dir

      if network.nodes.empty?
        raise "No aws, vbox, libvirt, docker nodes found in #{args[0]}"
      end

      if args[1].nil? # No node argument, copy keys to all nodes
        network.nodes.each do |node|
          keyfile_content = $exception_handler.handle("Keyfile not found! Check path to it!") { File.read("#{pwd.to_s}/#{@keyFile.to_s}") }
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
        keyfile_content = $exception_handler.handle("Keyfile not found! Check path to it!") { File.read("#{pwd.to_s}/#{@keyFile.to_s}") }
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

  def showProvider(name)
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
    templateNodes = $exception_handler.handle('Template configuration file invalid') { JSON.parse(IO.read(@mdbciDir.to_s+"/"+templateFile)) }
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


  def cloneNodes(configuration, new_path)
    copying_old_config_to_new(configuration, new_path)
    provider = get_provider(new_path)
    if provider == DOCKER
      dockerCloneNodes(configuration, new_path)
    elsif provider == LIBVIRT
      libvirtCloneNodes(configuration, new_path)
    else
      raise "#{provider}: provider does not support cloning"
    end
  end


  def dockerCloneNodes(old_path, new_path)
  end

end

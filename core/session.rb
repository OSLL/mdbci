require 'json'
require 'fileutils'
require 'uri'
require 'open3'

require_relative 'generator'
require_relative 'network'
require_relative 'boxes_manager'
require_relative 'repo_manager'


class Session

  attr_accessor :boxes
  attr_accessor :configs
  attr_accessor :versions
  attr_accessor :configFile
  attr_accessor :boxesFile
  attr_accessor :awsConfig        # aws-config parameters
  attr_accessor :awsConfigFile    # aws-config.yml file
  attr_accessor :awsConfigOption  # path to aws-config.yml in template file
  attr_accessor :isOverride
  attr_accessor :isSilent
  attr_accessor :command
  attr_accessor :repos
  attr_accessor :repoDir
  attr_accessor :mdbciNodes       # mdbci nodes
  attr_accessor :templateNodes
  attr_accessor :nodesProvider   # current configuration provider
  attr_accessor :attempts
  attr_accessor :boxesDir
  attr_accessor :mdbciDir
  attr_accessor :nodeProduct
  attr_accessor :productVersion
  attr_accessor :keyFile
  attr_accessor :boxPlatform
  attr_accessor :boxPlatformVersion

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
    @awsConfig = $exception_handler.handle('AWS configuration file not found') {YAML.load_file(@awsConfigFile)['aws']}

    $out.info 'Load Repos from '+$session.repoDir
    @repos = RepoManager.new($session.repoDir)

  end

  def setup(what)

    exit_code = 0
    possibly_failed_command = ''

    case what
      when 'boxes'
        $out.info 'Adding boxes to vagrant'
        @boxes.boxesManager.each do |key, value|
          next if value['provider'] == "aws" # skip 'aws' block
          # TODO: add aws dummy box
          # vagrant box add dummy https://github.com/mitchellh/vagrant-aws/raw/master/dummy.box

          next if value['provider'] == "mdbci" # skip 'mdbci' block
          #
          if value['box'].to_s =~ URI::regexp # THERE CAN BE DONE CUSTOM EXCEPTION
            puts 'vagrant box add '+key.to_s+' '+value['box'].to_s
            shell = 'vagrant box add '+key.to_s+' '+value['box'].to_s
          else
            puts 'vagrant box add --provider virtualbox '+value['box'].to_s
            shell = 'vagrant box add --provider virtualbox '+value['box'].to_s
          end

          # TODO: resque Exeption
          system shell # THERE CAN BE DONE CUSTOM EXCEPTION

          exit_code = $?.exitstatus
          possibly_failed_command = shell

        end
      else
        $out.warning 'Cannot setup '+what
        return 1
    end

    if exit_code != 0
      $out.error "command 'setup' exit with non-zero exit code: #{exit_code}"
      $out.error "failed command: #{possibly_failed_command}"
      exit_code = 1
    end

    return exit_code

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
      return 1
    end

    config = args.split('/')
    unless Dir.exists?(config[0])
      $out.error 'Machine with such name does not exists'
      return 1
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
    instanceFile = $exception_handler.handle('INSTANCE configuration file not found'){IO.read(pwd+'/template')}
    $out.info 'Load nodes from template file ' + instanceFile.to_s
    @templateNodes = $exception_handler.handle('INSTANCE configuration file invalid'){JSON.parse(IO.read(@mdbciDir+'/'+instanceFile))}
    if @templateNodes.has_key?('cookbook_path') ; @templateNodes.delete('cookbook_path') ; end
    if @templateNodes.has_key?('aws_config') ; @templateNodes.delete('aws_config') ; end
  end

  # load mdbci nodes
  def loadMdbciNodes(path)
    templateFile = $exception_handler.handle('MDBCI configuration file not found') {IO.read(path+'/mdbci_template')}
    $out.info 'Read template file ' + templateFile.to_s
    @mdbciNodes =  $exception_handler.handle('MDBCI configuration file invalid') {JSON.parse(IO.read(templateFile))}
    # delete cookbook_path and aws_config
    if @mdbciNodes.has_key?("cookbook_path") ; @mdbciNodes.delete("cookbook_path") ; end
    if @mdbciNodes.has_key?("aws_config") ; @mdbciNodes.delete("aws_config") ; end
  end

  # ./mdbci ssh command for AWS, VBox and PPC64 machines
  def ssh(args)
    exit_code = 1
    possibly_failed_command = ''
    pwd = Dir.pwd

    if args.nil?
      $out.error 'Configuration name is required'
      return 1
    end

    params = args.split('/')
    # mdbci ppc64 boxes
    if File.exist?(params[0]+'/mdbci_template')
      loadMdbciNodes params[0]
      if params[1].nil?     # ssh for all nodes
        @mdbciNodes.each do |node|
          box = node[1]['box'].to_s
          if !box.empty?
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
        end
      else
        mdbci_node = @mdbciNodes.find { |elem| elem[0].to_s == params[1] }
        box = mdbci_node[1]['box'].to_s
        if !box.empty?
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
      end
    else # aws, vbox nodes
      unless Dir.exist?(params[0])
        $out.error 'Machine with such name does not exist'
        return 1
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
    key = $session.boxes.boxesManager.keys.select {|value| value == box_name }
    return key.nil? ? "UNKNOWN" : $session.boxes.boxesManager[key[0]]['platform']+'^'+$session.boxes.boxesManager[key[0]]['platform_version']
  end


  def showBoxKeys
    $session.boxes.boxesManager.values.each do |value|
      $out.out value['$key']
    end
  end


  # show boxes with platform and version
  def showBoxes

    exit_code = 1

    if $session.boxPlatform.nil?
      $out.warning './mdbci show boxes --platform command option is not defined!'
      return 1
    elsif $session.boxPlatform.nil? and $session.boxPlatformVersion.nil?
      $out.warning './mdbci show boxes --platform or --platform-version command parameters are not defined!'
      return 1
    end
    # check for undefined box
    some_box = $session.boxes.boxesManager.find { |box| box[1]['platform'] == $session.boxPlatform }
    if some_box.nil?
      $out.warning 'Platform '+$session.boxPlatform+' is not supported!'
      return 1
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

  def show(collection)
    exit_code = 1
    case collection
      when 'boxes'
        exit_code = showBoxes
      when 'repos'
        @repos.show
      when 'versions'
        exit_code = boxesPlatformVersions
      when 'platforms'
        $out.out @boxes.keys
      when 'network'
        exit_code = Network.show(ARGV.shift)
      when 'private_ip'
        exit_code = Network.private_ip(ARGV.shift)
      when 'keyfile'
        exit_code = Network.showKeyFile(ARGV.shift)
      when 'boxkeys'
        showBoxKeys
      when 'provider'
        exit_code = showProvider(ARGV.shift)
      else
        $out.error 'Unknown show command collection: '+collection
    end
    return exit_code
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
    else
      $out.error 'Unknown mdbci command. Please look help!'
      Help.display
    end
    return exit_code
  end

  # load mdbci boxes parameters from boxes.json
  def LoadNodesProvider(configs)
    configs.each do |node|
      box = node[1]['box'].to_s
      if !box.empty?
        box_params = @boxes.getBox(box)
        @nodesProvider = box_params["provider"].to_s
      end
    end
  end

  def generate(name)
    exit_code = 1
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
      $out.warning 'Instance configuration file not found!'
      return 1
    end
    instanceConfigFile = $exception_handler.handle('INSTANCE configuration file not found'){IO.read($session.configFile)}
    if instanceConfigFile.nil?
      $out.warning 'Instance configuration file invalid!'
      return 1
    end
    @configs = $exception_handler.handle('INSTANCE configuration file invalid'){JSON.parse(instanceConfigFile)}
    if @configs.nil?
      $out.out 'Template configuration file is empty!'
      return 1
    else
      LoadNodesProvider configs
    end
    #
    aws_config = @configs.find { |value| value.to_s.match(/aws_config/) }
    @awsConfigOption = aws_config.to_s.empty? ? '' : aws_config[1].to_s
    #
    if @nodesProvider != 'mdbci'
      exit_code = Generator.generate(path,configs,boxes,isOverride,nodesProvider)
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
    if !File.exists?(provider_file)
      File.open(path+'/provider', 'w') { |f| f.write(@nodesProvider.to_s) }
    end
    if @nodesProvider != 'mdbci'
      template_file = path+'/template'
      if !File.exists?(template_file); File.open(path+'/template', 'w') { |f| f.write(configFile.to_s) }; end
    end

    return exit_code
  end

  # Deploy configurations
  def up(args)
    std_q_attampts = 10
    exit_code = 1 # error

    # No arguments provided
    if args.nil?
      $out.info 'Command \'up\' needs one argument, found zero'
      return
    end

    # No attempts provided
    if @attempts.nil?
      @attempts = std_q_attampts
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

    up_type ? Dir.chdir(config[0]) : Dir.chdir(args)

    # Setting provider: VBox, AWS, Libvirt, Docker
    @nodesProvider = $exception_handler.handle("File with PROVIDER info not found"){File.read('provider')}
    $out.info 'Current provider: ' + @nodesProvider
    if @nodesProvider == 'mdbci'
      $out.warning 'You are using mdbci nodes template. ./mdbci up command doesn\'t supported for this boxes!'
      return 0
    else
      (1..@attempts.to_i).each do |i|
        $out.info 'Bringing up ' + (up_type ? 'node ' : 'configuration ') +
          args + ', attempt: ' + i.to_s

        if i == 1
          $out.info 'Destroying current instance'
          cmd_destr = 'vagrant destroy --force ' + (up_type ? config[1]:'')
          exec_cmd_destr = `#{cmd_destr}`
          $out.info exec_cmd_destr
        end

        no_parallel_flag = ""
        if @nodesProvider == "aws"
          no_parallel_flag = " --no-parallel "
        end

        cmd_up = 'vagrant up' + no_parallel_flag + ' --provider=' + @nodesProvider + ' ' +
          (up_type ? config[1]:'')
        $out.info 'Actual command: ' + cmd_up
        Open3.popen3(cmd_up) do |stdin, stdout, stderr, wthr|
          stdin.close
          stdout.each_line { |line| $out.info line }
          stdout.close
          if !wthr.value.success?
            $out.error 'Bringing up failed'
            stderr.each_line { |line| $out.error line }
            stderr.close
   	        exit_code = wthr.value.exitstatus # error
	          $out.error 'exit code '+exit_code.to_s
	        else
            $out.info 'Configuration UP SUCCESS!'
            return 0
          end
  	    end

        if exit_code != 0
          $out.info "Checking for all nodes to be started"
          all_machines_started = true
          invalid_states = ["not created", "poweroff"]
          Dir.glob('*.json', File::FNM_DOTMATCH) do |f|
            machine_name = f.chomp! ".json"
            status = `vagrant status #{machine_name}`.split("\n")[2]
            invalid_states.each do |state|
              if status.include? state
                all_machines_started = false
                $out.error "Machine #{machine_name} is in #{state} state"
              end
            end
          end

          if i == @attempts && !all_machines_started
            $out.error 'Bringing up failed'
            $out.error 'Some machines are still down'
            exit_code = 1
          end
        end
      end
    end

    Dir.chdir pwd

    return exit_code
  end


  # copy ssh keys to config/node
  def publicKeys(args)
    pwd = Dir.pwd
    possibly_failed_command = ''
    exit_code = 1

    if args.nil?
      $out.error 'Configuration name is required'
      return 1
    end

    args = args.split('/')

    # mdbci box
    if File.exist?(args[0]+'/mdbci_template')
      loadMdbciNodes args[0]
      if args[1].nil?     # read ip for all nodes
        if $session.mdbciNodes.empty?
          $out.error "MDBCI nodes not found in #{args[0]}"
          return 1
        end
        $session.mdbciNodes.each do |node|
          box = node[1]['box'].to_s
          if !box.empty?
            mdbci_params = $session.boxes.getBox(box)
            #
            keyfile_content = $exception_handler.handle("Keyfile not found! Check keyfile path!"){File.read(pwd.to_s+'/'+@keyFile.to_s)}
            # add keyfile_content to the end of the authorized_keys file in ~/.ssh directory
            command = 'echo \''+keyfile_content+'\' >> /home/'+mdbci_params['user']+'/.ssh/authorized_keys'
            cmd = 'ssh -i ' + pwd.to_s+'/KEYS/'+mdbci_params['keyfile'].to_s + " "\
                            + mdbci_params['user'].to_s + "@" + mdbci_params['IP'].to_s + " "\
                            + "\"" + command + "\""
            $out.info 'Copy '+@keyFile.to_s+' to '+node[0].to_s
            vagrant_out = `#{cmd}`
            # TODO
            exit_code = $?.exitstatus
            possibly_failed_command = cmd
          end
        end
      else
        mdbci_node = @mdbciNodes.find { |elem| elem[0].to_s == args[1] }

        if mdbci_node.nil?
          $out.error "No such node with name #{args[1]} in #{args[0]}"
          return 1
        end

        box = mdbci_node[1]['box'].to_s
        if !box.empty?
          mdbci_params = $session.boxes.getBox(box)
          #
          keyfile_content = $exception_handler.handle("Keyfile not found! Check keyfile path!"){File.read(pwd.to_s+'/'+@keyFile.to_s)}
          # add to the end of the authorized_keys file in ~/.ssh directory
          command = 'echo \''+keyfile_content+'\' >> /home/'+mdbci_params['user']+'/.ssh/authorized_keys'
          cmd = 'ssh -i ' + pwd.to_s+'/KEYS/'+mdbci_params['keyfile'].to_s + " "\
                          + mdbci_params['user'].to_s + "@" + mdbci_params['IP'].to_s + " "\
                          + "\"" + command + "\""
          $out.info 'Copy '+@keyFile.to_s+' to '+mdbci_node[0].to_s
          vagrant_out = `#{cmd}`
          # TODO
          exit_code = $?.exitstatus
          possibly_failed_command = cmd
        else
          $out.error "Wrong box parameter in node: #{args[1]}"
          return 1
        end
      end
    else # aws, vbox, libvirt, docker nodes

      unless Dir.exists? args[0]
        $out.error "Directory with nodes does not exists: #{args[1]}"
        return 1
      end

      network = Network.new
      network.loadNodes args[0] # load nodes from dir

      if network.nodes.empty?
        $out.error "No aws, vbox, libvirt, docker nodes found in #{args[0]}"
        return 1
      end

      if args[1].nil? # No node argument, copy keys to all nodes
        network.nodes.each do |node|
          keyfile_content = $exception_handler.handle("Keyfile not found! Check path to it!"){File.read("#{pwd.to_s}/#{@keyFile.to_s}")}
          # add keyfile content to the end of the authorized_keys file in ~/.ssh directory
          cmd = 'vagrant ssh '+node.name.to_s+' -c "echo \''+keyfile_content+'\' >> ~/.ssh/authorized_keys"'
          $out.info 'Copy '+@keyFile.to_s+' to '+node.name.to_s+'.'
          vagrant_out = `#{cmd}`
          exit_code = $?.exitstatus
          possibly_failed_command = cmd
          $out.out vagrant_out
        end
      else
        node = network.nodes.find { |elem| elem.name == args[1]}

        if node.nil?
          $out.error "No such node with name #{args[1]} in #{args[0]}"
          return 1
        end

        #
        keyfile_content = $exception_handler.handle("Keyfile not found! Check path to it!"){File.read("#{pwd.to_s}/#{@keyFile.to_s}")}
        # add keyfile content to the end of the authorized_keys file in ~/.ssh directory
        cmd = 'vagrant ssh '+node.name.to_s+' -c "echo \''+keyfile_content+'\' >> ~/.ssh/authorized_keys"'
        $out.info 'Copy '+@keyFile.to_s+' to '+node.name.to_s+'.'
        vagrant_out = `#{cmd}`
        exit_code = $?.exitstatus
        possibly_failed_command = cmd
        $out.out vagrant_out
      end
    end

    Dir.chdir pwd

    if exit_code != 0
      $out.error "command #{possibly_failed_command} exit with non-zero code: #{exit_code}"
      exit_code = 1
    end

    return exit_code

  end

  def showProvider(name)
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
  def boxesPlatformVersions

    if $session.boxPlatform == nil
      $out.error "Specify parameter --platforms and try again"
      return 1
    end

    # check for supported platforms
    some_platform = $session.boxes.boxesManager.find { |box| box[1]['platform'] == $session.boxPlatform }
    if some_platform.nil?
      $out.error "Platform #{$session.boxPlatform} is not supported!"
      return 1
    else
      $out.info "Supported versions for #{$session.boxPlatform}:"
    end

    boxes_versions = Array.new

    # get boxes platform versions
    $session.boxes.boxesManager.each do |box, params|
      next if params['platform'] != $session.boxPlatform # skip unknown platform
      if params.has_value?($session.boxPlatform)
        box_platform_version = params['platform_version']
        boxes_versions.push(box_platform_version)
      else
        $out.error "#{$session.boxPlatform} has 0 supported versions! Please check box platform!"
      end
    end

    # output platforms versions
    boxes_versions = boxes_versions.uniq # delete duplicates values
    boxes_versions.each { |version| $out.out version }

    return 0
  end


  # load node platform by name
  def loadNodePlatform(name)
    pwd = Dir.pwd
    # template file
    templateFile = $exception_handler.handle('Template nodes file not found') {IO.read(pwd.to_s+'/template')}
    templateNodes =  $exception_handler.handle('Template configuration file invalid') {JSON.parse(IO.read(@mdbciDir.to_s+"/"+templateFile))}
    #
    node = templateNodes.find { |elem| elem[0].to_s == name }
    box = node[1]['box'].to_s
    if $session.boxes.boxesManager.has_key?(box)
      box_params = $session.boxes.getBox(box)
      platform = box_params["platform"].to_s+'^'+box_params['platform_version'].to_s
      return platform
    else
      $out.warning name.to_s+" platform does not exist! Please, check box name!"
    end

  end

end

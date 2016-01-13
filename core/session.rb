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
  attr_accessor :nodesProvider   # current configuration provider
  attr_accessor :attempts
  attr_accessor :boxesDir
  attr_accessor :mdbciDir

  def initialize
    @boxesDir = './BOXES'
    @repoDir = './repo.d'
    @mdbciNodes = Hash.new
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
        end
      else
        $out.warn 'Cannot setup '+what
    end
  end

  def checkConfig
    #TODO #6267
    $out.info 'Checking this machine configuration requirments'
    $out.info '.....NOT IMPLEMENTED YET'
  end

  def sudo(args)

    if args.nil?
      $out.error 'Configuration name is required'
      return
    end

    config = args.split('/')

    pwd = Dir.pwd
    Dir.chdir config[0]

    cmd = 'vagrant ssh '+config[1]+' -c "/usr/bin/sudo '+$session.command+'"'

    $out.info 'Running ['+cmd+'] on '+config[0]+'/'+config[1]

    vagrant_out = `#{cmd}`
    $out.out vagrant_out

    Dir.chdir pwd
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

    pwd = Dir.pwd

    if args.nil?
      $out.error 'Configuration name is required'
      return
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
          $out.out vagrant_out
        end
      end
    else # aws, vbox nodes
      Dir.chdir params[0]
      cmd = 'vagrant ssh '+params[1].to_s+' -c "'+$session.command+'"'
      $out.info 'Running ['+cmd+'] on '+params[0].to_s+'/'+params[1].to_s

      vagrant_out = `#{cmd}`
      $out.out vagrant_out

      Dir.chdir pwd
    end


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


  def show(collection)
    case collection
      when 'boxes'
        $out.out JSON.pretty_generate(@boxes)

      when 'repos'
        @repos.show

      when 'versions'
        $out.out @versions

      when 'platforms'
        $out.out  @boxes.keys

      when 'network'
        Network.show(ARGV.shift)

      when 'private_ip'
        Network.private_ip(ARGV.shift)

      when 'keyfile'
        Network.showKeyFile(ARGV.shift)

      when 'boxkeys'
        showBoxKeys

      when 'provider'
        exit_code = showProvider(ARGV.shift)

      else
        $out.error 'Unknown collection: '+collection
    end
    return exit_code
  end

  # all mdbci commands swith
  def commands
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

    else
      exit_code = 1
      puts 'ERR: Something wrong with command line'
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
    path = Dir.pwd

    if name.nil?
      path += '/default'
    else
      path +='/'+name.to_s
    end
    #
    instanceConfigFile = $exception_handler.handle('INSTANCE configuration file not found'){IO.read($session.configFile)}
    @configs = $exception_handler.handle('INSTANCE configuration file invalid'){JSON.parse(instanceConfigFile)}
    LoadNodesProvider(configs)
    #
    aws_config = @configs.find { |value| value.to_s.match(/aws_config/) }
    @awsConfigOption = aws_config.to_s.empty? ? '' : aws_config[1].to_s
    #
    if @nodesProvider != 'mdbci'
      Generator.generate(path,configs,boxes,isOverride,nodesProvider)
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
      (1..@attempts.to_i).each { |i|
        $out.info 'Bringing up ' + (up_type ? 'node ' : 'configuration ') + 
          args + ', attempt: ' + i.to_s
        $out.info 'Destroying current instance'
        cmd_destr = 'vagrant destroy --force ' + (up_type ? config[1]:'')
        exec_cmd_destr = `#{cmd_destr}`
        $out.info exec_cmd_destr
        cmd_up = 'vagrant up --destroy-on-error ' + '--provider=' + @nodesProvider + ' ' +
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
	          $out.info 'UP ERROR, exit code '+exit_code.to_s
	        else
  	        exit_code = 0 # success
            $out.info 'UP SUCCESS, exit code '+exit_code.to_s
          end
  	    end
      }
    end
    Dir.chdir pwd
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

  # TODO: refactoring this function!
  # load node platform by name
  def loadNodePlatformBy(name)

    pwd = Dir.pwd
    # template file
    templateFile = $exception_handler.handle('Template nodes file not found') {IO.read(pwd.to_s+'/template')}
    templateNodes =  $exception_handler.handle('Template configuration file invalid') {JSON.parse(IO.read(@mdbciDir.to_s+"/"+templateFile))}
    #
    node = templateNodes.find { |elem| elem[0].to_s == name }
    box = node[1]['box'].to_s
    if $session.boxes.boxesManager.has_key?(box)
      box_params = $session.boxes.getBox(box)
      platform = box_params["platform"].to_s
      return platform
    else
      $out.warning name.to_s+" platform does not exist! Please, check box name!"
    end

  end

end

require 'json'
require 'fileutils'
require 'uri'
require 'open3'

require_relative 'generator'
require_relative 'network'
require_relative 'repo_manager'

class Session

  attr_accessor :boxes
  attr_accessor :configs
  attr_accessor :versions
  attr_accessor :configFile
  attr_accessor :boxesFile
  attr_accessor :awsConfigFile    # aws-config.yml file
  attr_accessor :awsConfig        # aws-config parameters
  attr_accessor :awsConfigOption  # aws-config option from template.json
  attr_accessor :isOverride
  attr_accessor :isSilent
  attr_accessor :command
  attr_accessor :repos
  attr_accessor :repoDir
  attr_accessor :mdbciNodes       # mdbci nodes
  attr_accessor :nodesProvider   # current configuration provider
  attr_accessor :attempts

  def initialize
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

    $out.info 'Load boxes from ' + $session.boxesFile
    @boxes = JSON.parse(IO.read($session.boxesFile))
    $out.info 'Found boxes: ' + $session.boxes.size().to_s

    $out.info 'Load AWS config from ' + @awsConfigFile
    @awsConfig = YAML.load_file(@awsConfigFile)['aws']

    $out.info 'Load Repos from '+$session.repoDir
    @repos = RepoManager.new($session.repoDir)
  end

   def inspect
     @boxes.to_json
   end

  def setup(what)
    case what
      when 'boxes'
        $out.info 'Adding boxes to vagrant'
        boxes = JSON.parse(inspect) # json to hash
        boxes.each do |key, value|
          next if value['provider'] == "aws" # skip 'aws' block
          next if value['provider'] == "mdbci" # skip 'mdbci' block
          #
          if value['box'].to_s =~ URI::regexp
            puts 'vagrant box add '+key.to_s+' '+value['box'].to_s
            shell = 'vagrant box add '+key.to_s+' '+value['box'].to_s
          else
            puts 'vagrant box add --provider virtualbox '+value['box'].to_s
            shell = 'vagrant box add --provider virtualbox '+value['box'].to_s
          end

          system shell
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
    templateFile = IO.read(path+'/mdbci_config.ini')
    $out.info 'Read template file ' + templateFile.to_s
    @mdbciNodes = JSON.parse(IO.read(templateFile))
    $session.boxes = JSON.parse(IO.read($session.boxesFile))
  end

  # ./mdbci ssh command for AWS and VBox machines
  #     VBox, AWS: mdbci ssh --command "touch file.txt" config_dir/node0 --silent
  # TODO: for PPC64 box - execute ssh -i keyfile.pem user@ip
  def ssh(args)

    if args.nil?
      $out.error 'Configuration name is required'
      return
    end

    params = args.split('/')

    pwd = Dir.pwd
    Dir.chdir params[0]

    cmd = 'vagrant ssh '+params[1]+' -c "'+$session.command+'"'
    $out.info 'Running ['+cmd+'] on '+params[0]+'/'+params[1]

    vagrant_out = `#{cmd}`
    $out.out vagrant_out

    Dir.chdir pwd

  end


  def platformKey(box_name)
    key = @boxes.keys.select {|value| value == box_name }
    return key.nil? ? "UNKNOWN" : @boxes[key[0]]['platform'] + '^' +@boxes[key[0]]['platform_version']
  end


  def showBoxKeys
    @boxes.values.each do |value|
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

      else
        $out.error 'Unknown collection: '+collection
    end
  end

  # load mdbci boxes parameters from boxes.json
  def LoadNodesProvider(configs)
    configs.each do |node|
      box = node[1]['box'].to_s
      if !box.empty?
        box_params = boxes[box]
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
    @configs = JSON.parse(IO.read($session.configFile))
    LoadNodesProvider(configs)
    #
    aws_config = @configs.find { |value| value.to_s.match(/aws_config/) }
    awsConfig = aws_config.to_s.empty? ? '' : aws_config[1].to_s
    #
    if @nodesProvider != "mdbci"
      Generator.generate(path,configs,boxes,isOverride,awsConfig,nodesProvider)
      $out.info 'Generating config in ' + path
    else
      $out.info "Using mdbci ppc64 box definition, generating config in " + path + "/mdbci_config.ini"
      # TODO: dir already exist?
      Dir.mkdir path unless File.exists? path
      mdbci = File.new(path+'/mdbci_config.ini', 'w')
      mdbci.print $session.configFile
      mdbci.close
    end
  end

  # Deploy configurations
  def up(args)
    std_q_attampts = 4
    std_err_val = 1

    # No arguments provided
    if args.nil?
      $out.info 'Command \'up\' needs one argument, found zero'
      return std_err_val
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

    # Setting provider: VirtualBox, AWS, (,libvirt)
    if File.exist?('provider')
      @nodesProvider = File.read('provider')
    else
      $out.warning 'File "provider" does not found! Try to regenerate your configuration!'
    end
    $out.info 'Current provider: ' + @nodesProvider

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
        if wthr.value.success?
          Dir.chdir pwd
          return 0
        end
        $out.error 'Bringing up failed'
        stderr.each_line { |line| $out.error line }
        stderr.close
      end
    }
    Dir.chdir pwd
    return std_err_val
  end
end

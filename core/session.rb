require 'json'
require 'fileutils'
require 'uri'

require_relative 'generator'
require_relative 'network'
require_relative 'repo_manager'

class Session

  attr_accessor :boxes
  attr_accessor :configs
  attr_accessor :versions
  attr_accessor :configFile
  attr_accessor :boxesFile
  attr_accessor :isOverride
  attr_accessor :isSilent
  attr_accessor :command
  attr_accessor :awsConfig
  attr_accessor :repos
  attr_accessor :repoDir
  attr_accessor :mdbciNodes       # mdbci nodes
  attr_accessor :nodesProvider    # current configuration provider

  def initialize
    @repoDir = './repo.d'
    @mdbciNodes = Hash.new
  end

=begin
     Load collections from json files:
      - boxes.json.json
      - versions.json
=end

  def loadCollections

    $out.info 'Load boxes from ' + $session.boxesFile
    @boxes = JSON.parse(IO.read($session.boxesFile))
    $out.info 'Found boxes: ' + $session.boxes.size().to_s

    $out.info 'Load Repos from '+$session.repoDir
    @repos = RepoManager.new($session.repoDir)


    # TODO: Load vbox and aws nodes params to runtime variables


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

  # ./mdbci ssh command for AWS and VBox machines
  #     VBox, AWS: mdbci ssh --command "touch file.txt" config_dir/node0 --silent
  # TODO: for PPC64 box - execute ssh -i keyfile.pem user@ip
  def ssh(args)

    if args.nil?
      $out.error 'Configuration name is required'
      return
    end

    # TODO: check if one word
    params = args.split('/')

    # mdbci nodes
    if File.exist?(params[0]+'/mdbci_config.ini')
      templateFile = IO.read(params[0]+'/mdbci_config.ini')
      template = JSON.parse(IO.read(templateFile))
      $session.boxes = JSON.parse(IO.read($session.boxesFile))
      # read configuration
      if params[1].nil?     # read keyfile for all nodes
        template.each do |node|
          host = node[1]['hostname'].to_s
          box = node[1]['box'].to_s
          if !box.empty?
            box_params = $session.boxes[box]
            $out.out 'SSH command: ssh -i ' + box_params['keyfile'].to_s + " "\
                      + host.to_s + "@" + box_params['IP'].to_s + " "\
                      + "'" + $session.command + "'"
          end
        end
      else # read file for node args[1]
        #node = template.find { |elem| elem.name == params[0] }
        #p "NODE params: " + node["IP"].to_s + ", " + node["user"].to_s
        #cmd = 'ssh '+node["user"]+"@"+node["IP"]
        $out.out 'Not defined yet!'
      end
    else # aws, vbox nodes
      pwd = Dir.pwd
      Dir.chdir params[0]
      cmd = 'vagrant ssh '+params[1]+' -c "'+$session.command+'"'
      $out.info 'Running ['+cmd+'] on '+params[0]+'/'+params[1]

      vagrant_out = `#{cmd}`
      $out.out vagrant_out

      Dir.chdir pwd
    end


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

end
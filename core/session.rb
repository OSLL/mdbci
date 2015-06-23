require 'json'
require 'fileutils'
require 'uri'

require_relative 'generator'
require_relative 'network'

class Session

  attr_accessor :boxes
  attr_accessor :versions
  attr_accessor :configFile
  attr_accessor :boxesFile
  attr_accessor :isOverride
  attr_accessor :isSilent
  attr_accessor :command
  attr_accessor :awsConfig

=begin
     Load collections from json files:
      - boxes.json.json
      - versions.json
=end

  def loadCollections
    $out.info 'Load ' + $session.boxesFile
    @boxes = JSON.parse(IO.read($session.boxesFile))
    $out.info 'Load Versions'
  end

  def inspect
    @boxes.to_json
  end

  def setup(what)
    case what
      when 'boxes'
        p @boxes.keys
        $out.info 'Adding boxes to vagrant'
        p @boxes
        @boxes.each do |key, value|
          if value =~ URI::regexp
            shell = 'vagrant box add '+key+' '+value
          else
            shell = 'vagrant box add --provider virtualbox '+value
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

  def show(collection)
    case collection
      when 'boxes'
        $out.out JSON.pretty_generate(@boxes)
      when 'versions'
        $out.out @versions
      when 'platforms'
        $out.out  @boxes.keys
      when 'network'
        Network.show(ARGV.shift)
      when 'keyfile'
        Network.showKeyFile(ARGV.shift)
      else
        $out.error 'Unknown collection: '+collection
    end
  end

  def generate(name)
    path = Dir.pwd
    if name.nil?
      path += '/default'
    else
      path +='/'+name.to_s
    end

    config = JSON.parse(IO.read($session.configFile))
    #
    aws_config = config.find { |value| value.to_s.match(/aws_config/) }
    if aws_config.to_s.empty?
      awsConfig = ''
    else
      awsConfig = aws_config[1].to_s
    end
    #
    $out.info 'Generating config in ' + path
    Generator.generate(path,config,boxes,isOverride,awsConfig)

  end
end
require 'json'
require 'fileutils'
require 'uri'

class Session

  attr_accessor :isOverride, :configFile
  attr :boxes
  attr :versions

=begin
     Load collections from json files:
      - boxes.json.json
      - versions.json
=end

  def loadCollections
    puts 'Load boxes.json'
    @boxes = JSON.parse(IO.read('boxes.json'))
    puts 'Load Versions'
  end

  def inspect
    @boxes.to_json
  end

  def setup(what)
    case what
      when 'boxes'
        p @boxes.keys
        puts 'Adding boxes to vagrant'
        p @boxes
        @boxes.each do |key, value|
          if value =~ URI::regexp
            shell = 'vagrant box add '+key+' '+value
          else
            shell = shell = 'vagrant box add --provider virtualbox '+value
          end

          system shell
        end
      else
        puts 'Cannot setup '+what
    end
  end

  def checkConfig
    #TODO #6267
    puts 'Checking this machine configuration requirments'
    puts '.....NOT IMPLEMENTED YET'
  end

  def show(collection)
    case collection
      when 'boxes'
        puts JSON.pretty_generate(@boxes)
      when 'versions'
        puts @versions
      else
        puts 'Unknown collection: '+collection
    end
  end
end
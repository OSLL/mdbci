require 'json'

require_relative 'session'

class BoxesManager

  attr_accessor :boxesList  # Array of Box objects
  attr_accessor :boxesManager
  attr_accessor :providers

  def initialize(path)
    @boxesList = Array.new
    @boxesManager = Hash.new
    @providers = Hash.new

    lookup(path)

    # TODO: divide boxes for it's own provider
    @providers['virtualbox']='virtualbox'
    @providers['aws']='aws'
    @providers['libvirt']='libvirt'
    @providers['mdbci']='mdbci'
    @providers['docker']='docker'
  end

  def lookup(path)
    Dir.glob(path+'/*.json', File::FNM_DOTMATCH) do |f|
      addBoxes(f)
    end
    $out.info 'Loaded boxes: ' + @boxesManager.size.to_s
  end

  def addBoxes(file)
    begin
      fileBoxes = JSON.parse(IO.read(file))
      # combine all boxes hashes
      @boxesManager = @boxesManager.merge(fileBoxes)
    rescue
      $out.warning 'Invalid file format: '+file.to_s + ' SKIPPED!'
    end
  end

  def getBox(key)
    $session.boxes.boxesManager[key]
  end

  def platformKey(box_name)
    key = $session.boxes.boxesManager.keys.select {|value| value == box_name }
    return key.nil? ? "UNKNOWN" : @boxesManager[key[0]]['platform']+'^'+$session.boxes.boxesManager[key[0]]['platform_version']
  end

  def showBoxKeys
    $session.boxes.boxesManager.values.each do |value|
      $out.out value['$key']
    end
  end


  # TODO refactoring: create class Box with boxes get/set methods. Add boxes while parsing BOXES/*.json
  def BoxesManager.getBoxesList(platform, version)
    exit_code = 1
    #
    if platform.nil?
      $out.warning '--platform option is missing! Please, point box platform!'
      exit_code = 1
    elsif platform.nil? and version.nil?
      $out.warning '--platform or --platform-version options are missing!'
      exit_code = 1
    end
    if $session.boxes.boxesManager.nil?
      $out.warning 'Boxes are not parsed!'
      exit_code = 1
    end
    # check for undefined box
    some_box = $session.boxes.boxesManager.find { |box| box[1]['platform'] == platform }
    if some_box.nil?
      $out.warning 'Platform '+platform+' is not supported!'
      exit_code = 1
    end
    #
    $out.info platform+' platform boxes list:'
    $session.boxes.boxesManager.each do |box, params|
      if params.has_value?($session.boxPlatform) and $session.boxPlatformVersion.nil?
        $session.boxes.boxesList.push(box)
        exit_code = 0
      elsif params.has_value?($session.boxPlatform) and params.has_value?($session.boxPlatformVersion)
        $session.boxes.boxesList.push(box)
        exit_code = 0
      end
    end
    return exit_code
  end
  # print boxes with platform and version
  def BoxesManager.printBoxes(boxes)
    exit_code = 1
    exit_code = getBoxesList($session.boxPlatform, $session.boxPlatformVersion)
    if !boxes.nil? and exit_code != 1
      boxes.each { |box| $out.out box.to_s }
      exit_code = 0
    else
      $out.warning 'Boxes list is empty for the '+$session.boxPlatform+' platform!'
      exit_code = 1
    end
    return exit_code
  end

  # show boxes
  def self.showBoxes
    return printBoxes($session.boxes.boxesList)
  end

end

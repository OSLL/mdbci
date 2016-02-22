require 'json'

require_relative 'session'

class BoxesManager

  attr_accessor :boxesList    # Array for parsed boxes
  attr_accessor :boxesManager # Hash with all boxes

  def initialize(path)
    @boxesList = Array.new
    @boxesManager = Hash.new

    lookup(path)
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
      $out.warning 'Platform '+platform.to_s+' is not supported!'
      exit_code = 1
    end
    #
    $session.boxes.boxesManager.each do |box, params|
      if params.has_value?(platform) and version.nil?
        $session.boxes.boxesList.push(box)
        exit_code = 0
      elsif params.has_value?(platform) and params.has_value?(version)
        $session.boxes.boxesList.push(box)
        exit_code = 0
      end
    end
    return exit_code
  end
  # print boxes with platform and version
  def BoxesManager.printBoxes(boxes)
    exit_code = getBoxesList($session.boxPlatform, $session.boxPlatformVersion)
    if !boxes.nil? and exit_code != 1
      boxes.each { |box| $out.out box.to_s }
      exit_code = 0
    else
      $out.warning 'Boxes list is empty for the '+$session.boxPlatform.to_s+' platform!'
      exit_code = 1
    end
    return exit_code
  end

  # show boxes
  def self.showBoxes
    return printBoxes($session.boxes.boxesList)
  end

end

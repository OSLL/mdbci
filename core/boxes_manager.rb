require 'json'

require_relative 'session'

class BoxesManager

  attr_accessor :boxesList    # Array for parsed boxes
  attr_accessor :boxesManager # Hash with all boxes

  TEMPLATE = 'template'

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


  def getConfigPathAndNameByPath(path)
    directories = path.split('/')
    nodes_directory = ''
    node_name = ''

    if directories.empty?
      raise 'Path to generated nodes configurations is wrong'
    end

    if directories.length == 1
      nodes_directory = directories[0]
    elsif directories.length == 2
      nodes_directory = directories[0]
      node_name = directories[1]
    elsif directories.length > 2
      nodes_directory = directories[0..-2].join('/')
      node_name = directories[-1]
    end

    if !Dir.exists? nodes_directory
      raise 'Path to generated nodes configurations is wrong'
    end
    template_path = File.read(nodes_directory + '/' + TEMPLATE)
    return {"nodes_directory" => nodes_directory, "node_name" => node_name, "template_path" => template_path}
  end

  def getBoxByGeneratedConfig(path)
    pathParse = getConfigPathAndNameByPath(path)
    nodes_directory = pathParse['nodes_directory']
    node_name = pathParse['node_name']
    template_path = pathParse['template_path']
    if node_name.empty?
      boxes = Array.new
      get_nodes(nodes_directory).each do |node_name|
        boxes.push(getBoxByConfig(template_path, node_name))
      end
      raise "Boxes are not found for generated nodes configurations #{nodes_directory}" if boxes.empty?
      return boxes.uniq
    else
      return getBoxByConfig(template_path, node_name)
    end
  end

  def getBoxNameByPath(path)
    pathParse = getConfigPathAndNameByPath(path)
    template_path = pathParse['template_path']
    node_name = pathParse['node_name']
    return getBoxNameByConfig(template_path, node_name)
  end

  def getBoxNameByConfig(template_path, node_name)
    config = nil
    begin
      config = JSON.parse(File.read(template_path))
    rescue
      raise "Wrong config path or json implementation for #{template_path}"
    end
     
    if !config.has_key?(node_name)
      raise "Node #{node_name} is not found in #{template_path}"
    end

    return config[node_name]['box']
  end

  def getBoxByConfig(template_path, node_name)
    name = getBoxNameByConfig(template_path, node_name)
    box = getBox(name)
    raise "Box #{name} is not found" if box == nil
    return box
  end
end

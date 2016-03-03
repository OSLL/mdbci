require 'json'

class BoxesManager

  attr_accessor :boxesManager
  attr_accessor :providers

  TEMPLATE = 'template'

  def initialize(path)
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
    @boxesManager[key]
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
      Dir.glob(nodes_directory + '/*.json', File::FNM_DOTMATCH) do |f|
        boxes.push(getBoxByConfig(template_path, f.split('/')[-1].chomp('.json')))
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

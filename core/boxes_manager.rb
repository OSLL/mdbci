require 'json'

class BoxesManager

  attr_accessor :boxesManager
  attr_accessor :providers

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

  def getBoxByConfig(config_path, node_name)
    config = nil
    begin
      config = JSON.parse(File.read(config_path))
    rescue
      raise $out.ERROR +  "Wrong config path or json implementation for #{config_path}"
    end

    if config.has_key?(node_name)
      box = getBox(config[node_name]['box'])
      return box
    else
      raise $out.ERROR +  "Node #{node_name} is not found in #{config_path}"
    end
  end
end

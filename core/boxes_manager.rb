require 'json'

class BoxesManager

  attr_accessor :boxes
  attr_accessor :providers

  def initialize(path)
    @boxes= Hash.new
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
    $out.info 'Loaded boxes: ' + @boxes.size.to_s
  end

  def addBoxes(file)

    begin
      #$out.info 'Load boxes from ' + file
      fileBoxes = JSON.parse(IO.read(file))
      # combine all boxes hashes
      @boxes = @boxes.merge(fileBoxes)
    rescue
      $out.warning 'Invalid file format: '+file.to_s + ' SKIPPED!'
    end
  end

  def getBox(key)
    @boxes[key]
  end

end
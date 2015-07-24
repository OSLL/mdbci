require 'json'

class RepoManager

  attr_accessor :repos

  def initialize(path)
    @repos= Array.new
    lookup(path)
  end

  def lookup(path)
    $out.info 'Looking up for repos '+path

    Dir.glob(path+'/**/*.json', File::FNM_DOTMATCH) do |f|
      addRepo(f)
    end

    $out.info 'Loaded repos: ' + @repos.size.to_s
  end

  def addRepo(file)
    repo = JSON.parse(IO.read(file))

    #TODO check keys
    @repos << repo

  end
end
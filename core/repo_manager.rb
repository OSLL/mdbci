require 'json'

class RepoManager

  attr_accessor :repos
  attr_accessor :recipes  # product => recipe

  def initialize(path)
    @repos= Hash.new
    @recipes = Hash.new

    lookup(path)

    @recipes['mariadb']='mdbc'
    @recipes['maxscale']='mscale'
    @recipes['mysql']='mysql'
    @recipes['galera']='galera'
    @recipes['packages']='packages'
  end

  def recipeName(product)
    @recipes[product]
  end

  def findRepo(name, product, box)

    $out.info 'Looking for repo'

    version = (product['version'].nil? ? 'default' : product['version']);
    platform = $session.boxes.platformKey(box)
    repokey = name+'@'+version+'+'+ platform

    repo = @repos[repokey]
    $out.info 'Repo key is '+repokey + ' ... ' + (repo.nil? ? 'NOT_FOUND' : 'FOUND')

    return repo;
  end

  def show
    @repos.keys.each do |key|
      $out.out key + ' => [' +@repos[key]['repo'] +']'
    end
    0
  end

  def getRepo(key)
    repo = @repos[key]
    raise "Repository for key #{key} was not found" if repo.nil?
    return repo
  end

  def lookup(path)
    $out.info 'Looking up for repos '+path
    Dir.glob(path+'/**/*.json', File::FNM_DOTMATCH) do |f|
      addRepo(f)
    end
    raise 'Repositories was not found' if @repos.empty?
    $out.info 'Loaded repos: ' + @repos.size.to_s
  end

  def knownRepo?(repo)
    @repos.key?(repo)
  end

  def productName(repo)
    repo.to_s.split('@')[0]
  end

  def makeKey(product,version,platform,platform_version)
    if version.nil?
      version = '?'
    end

    product.to_s+'@'+version.to_s+'+'+platform.to_s+'^'+platform_version.to_s
  end

  def addRepo(file)
    #$out.info 'Processing '+file.to_s
    begin
      repo = JSON.parse(IO.read(file))

      if repo.kind_of?(Array)
        # in repo file arrays are allowed
        repo.each do |r|
          @repos[makeKey(r['product'],r['version'],r['platform'],r['platform_version'])] = r
        end
      else
        @repos[makeKey(repo['product'],repo['version'],repo['platform'],repo['platform_version'])] = repo
      end

      #TODO #6374 check keys
      #@repos << repo
    rescue
      $out.warning 'Invalid file format: '+file.to_s + ' SKIPPED!'
    end
  end
end

require 'json'

class RepoManager

  attr_accessor :repos

  def initialize(path)
    @repos= Hash.new
    lookup(path)
  end

  def show
    @repos.keys.each do |key|
      $out.out key + ' => [' +@repos[key]['repo'] +']'
    end
  end

  def lookup(path)
    $out.info 'Looking up for repos '+path

    Dir.glob(path+'/**/*.json', File::FNM_DOTMATCH) do |f|
      addRepo(f)
    end

    $out.info 'Loaded repos: ' + @repos.size.to_s
  end

  def makeKey(product,version,platform,platform_version)
    product.to_s+'@'+version.to_s+'_'+platform.to_s+'@'+platform_version.to_s
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
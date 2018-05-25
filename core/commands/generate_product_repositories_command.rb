# frozen_string_literal: true

require 'open-uri'
require 'optparse'
require 'nokogiri'
require 'pp'
require 'tmpdir'
require 'json'
require 'fileutils'
require 'logger'

require_relative 'base_command'

# The command generates the repository configuration
class GenerateProductRepositoriesCommand < BaseCommand
  CONFIGURATION_FILE = 'generate_repository_config.yaml'
  PRODUCTS_DIR_NAMES = {
    'columnstore' => 'columnstore',
    'community' => 'community',
    'galera' => 'galera',
    'maxscale_ci' => 'maxscale_ci',
    'maxscale' => 'maxscale',
    'mdbe' => 'mdbe',
    'mysql' => 'mysql'
  }
  COMMAND_NAME = 'generate-product-repositories'

  def self.synopsis
    'Generate product repository configuration for all known products'
  end

  # Show error message and help on how to use the command
  # @param [String] error_message text to display as en error.
  def show_error_and_help(error_message = '')
    if error_message
      error_and_log('There was an error during the command run.')
      error_and_log(error_message)
    end
    show_help
  end

  def show_help
  info = <<-EOF

'#{COMMAND_NAME} [REPOSITORY PATH]' creates product repository configuration.

Supported options:

--maxscale-ci name of the repository on the MaxScale CI server to add to MaxScale CI product configuration. Required if generating configuration for MaxScale CI server.
--configuration-file path to the configuration file to use during generation. Optional.
--product name of the product to generate repository configuration for. Optional.
--attempts number of attempts to try to get data from the remote repository. Default is 3 attempts.

In order to generate repo.d for all products using the default configuration.

  mdbci #{COMMAND_NAME} --maxscale-ci develop

You can create custom configuration file and use it during the repository creation:

  mdbci #{COMMAND_NAME} --maxscale-ci develop --configuration-file ~/mdbci/config/generate_repository_config.yaml

In order to specify the target directory pass it as the first parameter to the script.

  mdbci #{COMMAND_NAME} --maxscale-ci develop ~/mdbci/repo.d

In orded to generate configuration for a specific product use --product option.

  mdbci #{COMMAND_NAME} --product mdbe

In order to specify the number of retries for repository configuration use --attempts option.

  mdbci generate-product-repositories --product columnstore --attempts 5
EOF
  @ui.out(info)
  end

  def initialize(args, env, ui)
    super(args, env, ui)
    path = @env.data_path('generate_product_repository.log')
    @ui.info("Writing log file to #{path}")
    @logger = Logger.new(File.new(path, 'w'), 'weekly')
  end

  # Send info message to both user output and logger facility
  def info_and_log(message)
    @ui.info(message)
    @logger.info(message)
  end

  # Send error message to both direct output and logger facility
  def error_and_log(message)
    @ui.error(message)
    @logger.error(message)
  end

  # Use data provided via constructor to configure the command.
  def configure_command
    config_path = if @env.configuration_file
                    @env.configuration_file
                  else
                    @env.find_configuration(CONFIGURATION_FILE)
                  end
    unless File.exist?(config_path)
      show_error_and_help("Unable to find configuration file: '#{config_path}'.")
      return false
    end
    info_and_log("Configuring repositories using configuration: '#{config_path}'.")
    @config = YAML.load(File.read(config_path))
    @products = if @env.nodeProduct
                  unless PRODUCTS_DIR_NAMES.keys.include?(@env.nodeProduct)
                    show_error_and_help("Unknown product #{@env.nodeProduct}.\n" +
                                        "Known products: #{PRODUCT_DIR_NAMES.keys.join(', ')}")
                    return false
                  end
                  [@env.nodeProduct]
                else
                  PRODUCTS_DIR_NAMES.keys
                end
    info_and_log("Configuring repositories for products: #{@products.join(', ')}.")
    @attempts = if @env.attempts
                  @env.attempts.to_i
                else
                  3
                end
    info_and_log("The configuration will be attempted #{@attempts} times.")
    @destination = if @args.empty?
                     @env.configuration_path('repo.d')
                   else
                     @args.first
                   end
    info_and_log("Repository configuration will be written to '#{@destination}'.")
    @maxscale_ci = @env.maxscale_ci
    if @products.include?('maxscale_ci') && @maxscale_ci.nil?
      show_error_and_help('Please specify name of the CI repository to use for MaxScale CI repository configuration')
      return false
    end
    return true
  end

  # Get links on the specified page
  def get_links(repo_page, path = '/')
    uri = "#{repo_page}/#{path}"
    begin
      doc = Nokogiri::HTML(open(uri))
    rescue OpenURI::HTTPError => e
      raise OpenURI::HTTPError.new(e.message + ", uri: #{uri}", e.io)
    end
    doc.css('a')
  end

  # This method goes through the main page and finds releases that should be added to
  # the repository
  def find_viable_releases(repo_page)
    get_links(repo_page, '/').select do |link|
      dir_link?(link)
    end.select do |link|
      links = get_links(repo_page, link[:href])
                .map { |sublink| sublink.content }
      yield(link, links)
    end.map(&:content).map do |text|
      text.delete('/')
    end
  end

  def dir_link?(link)
    link.content =~ %r{\/$} || link[:href] =~ /^(?!((http|https):\/\/|\.{2}|\/|\?)).*\/$/
  end

  def create_repo(repo_page, systems, release_info, system, type, product, lambdas = {})
    @logger.info "Creating repository configuration for #{system} and #{product} #{release_info[:name]} release"
    system_type = systems[type]
    subpath = system_type[:path]
    repos = get_links(repo_page, "#{release_info[:path]}/#{subpath}").select do |link|
      if !lambdas[:repo_link_detector].nil?
        lambdas[:repo_link_detector].call(link)
      else
        link.content =~ %r{^#{system}(\/?)$}
      end
    end.each_with_object([]) do |link, repositories|
      repo_link = "#{release_info[:path]}/#{subpath}/#{link[:href]}".gsub(%r{\/\/}, '/')
      add_repo_from_platform_dir(product, release_info[:name], repo_link, repo_page, repositories, system, system_type)
    end

    lambdas[:result_handler].call(repos) unless lambdas[:result_handler].nil?

    return if repos.empty? || !lambdas[:result_handler].nil?
    FileUtils.mkdir_p("#{@directory}/#{system}")
    File.write("#{@directory}/#{system}/#{release_info[:name]}.json", JSON.pretty_generate(repos))
  end

  def add_repo_from_platform_dir(product, release, repo_link, repo_page, repositories, system, system_type)
    get_links(repo_page, system_type[:release_path].call(repo_link)).select do |link|
      dir_link?(link)
    end.each do |release_link|
      release_name = release_link.content.delete('/')
      repo_path = system_type[:repo_path].call(repo_link, release_name)
      repositories << {
        repo: repo_path,
        repo_key: system_type[:key].call(release),
        platform_version: release_name,
        platform: system,
        product: product,
        version: release
      }
    end
    repositories
  end

  def parse_product(config, product, lambdas = {}, systems_info = {}, release_info = {})
    systems = {
      debian: {
        path: '',
        repo_page: config['repo']['deb']['path'],
        key: ->(_version) { config['repo']['deb']['key'] },
        release_path: ->(repo_link) { "#{repo_link}/dists" },
        release_name: ->(release) { release },
        repo_path: lambda { |repo_link, release_name|
          "#{config['repo']['deb']['path']}#{repo_link} #{release_name} main"
        }
      },
      rhel: {
        path: '',
        repo_page: config['repo']['rpm']['path'],
        key: ->(_version) { config['repo']['rpm']['key'] },
        release_path: ->(repo_link) { repo_link },
        release_name: ->(release) { release },
        repo_path: lambda { |repo_link, release_name|
          "#{config['repo']['rpm']['path']}#{repo_link}/#{release_name}/x86_64"
        }
      }
    }
    systems.each_key do |system_type|
      systems[system_type].merge!(systems_info[system_type]) unless systems_info[system_type].nil?
    end

    systems.each do |system_type, system_info|
      if !release_info.nil? && !release_info[:path].nil? && !release_info[:name].nil?
        create_repo_for_platforms(config['platforms'], product, release_info, system_info, system_type, systems)
        next
      end

      find_viable_releases(system_info[:repo_page]) do |link, links|
        if !lambdas[:viable_release_detector].nil?
          lambdas[:viable_release_detector].call(system_type, system_info, link, links)
        else
          config['platforms'].map do |system_name|
            links.grep(%r{^#{system_name}(\/?)$}).any?
          end.any?
        end
      end.each do |release|
        current_release_info = { path: release, name: system_info[:release_name].call(release) }
        create_repo_for_platforms(config['platforms'], product, current_release_info, system_info, system_type, systems)
      end
    end
  end

  def create_repo_for_platforms(platforms, product, release_info, system_info, system_type, systems)
    @logger.info "Configuring #{product} release #{release_info[:name]}"
    platforms.each do |system_name|
      next if system_type != system_type_by_system_name(system_name)
      send("create_repo_#{product}".to_sym,
           system_info[:repo_page],
           systems,
           release_info,
           system_name,
           system_type)
    end
  end

  def create_repo_community(repo_page, systems, release, system, type)
    create_repo(repo_page, systems, release, system, type, 'mariadb')
  end

  def create_repo_columnstore(repo_page, systems, release, system, type)
    create_repo(
      repo_page,
      systems,
      release,
      system,
      type,
      'columnstore',
      repo_link_detector: lambda { |link|
        link.content.include?(system) && !link.content.include?('.')
      }
    )
  end

  def create_repo_galera(repo_page, systems, release, system, type)
    create_repo(repo_page, systems, release, system, type, 'galera')
  end

  def create_repo_mdbe(repo_page, systems, release, system, type)
    create_repo(repo_page, systems, release, system, type, 'mdbe')
  end

  def create_repo_maxscale_ci(repo_page, systems, release, system, type)
    create_repo(
      repo_page,
      systems,
      release,
      system,
      type,
      'maxscale_ci',
      result_handler: lambda { |repos|
        repos.each do |repo|
          platform = repo[:platform]
          platform_version = repo[:platform_version]
          File.write("#{@directory}/#{platform}-#{platform_version}.json", JSON.pretty_generate(repo))
        end
      }
    )
  end

  def create_repo_maxscale_release(repo_page, systems, release, system, type)
    create_repo(
      repo_page,
      systems,
      release,
      system,
      type,
      'maxscale',
      result_handler: lambda { |repos|
        repos.each do |repo|
          platform = repo[:platform]
          platform_version = repo[:platform_version]
          version = repo[:version]
          repo[:key] =
          File.write("#{@directory}/#{platform}_#{platform_version}_#{version}.json", JSON.pretty_generate(repo))
        end
      }
    )
  end

  def create_repo_mysql(repo_page, systems, release, system, type)
    create_repo(
      repo_page,
      systems,
      release,
      system,
      type,
      'mysql',
      repo_link_detector: lambda { |link|
        (%w[centos rhel].include?(system) && !(link.content =~ %r{^el(\/?)$}).nil?) ||
          (system == 'sles' && !(link.content =~ %r{^sles(\/?)$}).nil?)
      }
    )
  end

  def parse_community(config)
    parse_product(config, 'community')
  end

  def parse_columnstore(config)
    systems = {
      debian: {
        path: 'repo',
        repo_path: ->(repo_link, _release_name) { "#{config['repo']['deb']['path']}#{repo_link}" }
      },
      rhel: {
        path: 'yum'
      }
    }

    parse_product(
      config,
      'columnstore',
      {
        viable_release_detector: lambda { |_system_type, _system_info, _link, links|
          links.grep(%r{^yum(\/?)$}).any? && links.grep(%r{^repo(\/?)$}).any?
        }
      },
      systems
    )
  end

  def parse_galera(config)
    parse_product(config, 'galera')
  end

  def parse_mdbe(config)
    systems = {
      debian: {
        path: 'repo',
        repo_path: lambda { |repo_link, release_name|
          "#{config['repo']['deb']['path']}#{repo_link} #{release_name} main"
        }
      },
      rhel: {
        path: 'yum',
        repo_path: lambda { |repo_link, release_name|
          "#{config['repo']['rpm']['path']}#{repo_link}/#{release_name}"
        }
      }
    }

    parse_product(
      config,
      'mdbe',
      {
        viable_release_detector: lambda { |_system_type, _system_info, _link, links|
          links.grep(%r{^yum(\/?)$}).any? && links.grep(%r{^repo(\/?)$}).any?
        }
      },
      systems
    )
  end

  def parse_maxscale_ci(config)
    raise ArgumentError, 'Parameter maxscale_ci not specified' if @maxscale_ci.nil?
    ci = @maxscale_ci
    deb_repo_page = config['repo']['deb']['path'].sub('##ci##', ci)
    rpm_repo_page = config['repo']['rpm']['path'].sub('##ci##', ci)

    systems = {
      debian: {
        path: '',
        repo_page: deb_repo_page,
        repo_path: lambda { |repo_link, release_name|
          "#{deb_repo_page}#{repo_link} #{release_name} main"
        }
      },
      rhel: {
        path: '',
        repo_page: rpm_repo_page,
        repo_path: lambda { |repo_link, release_name|
          "#{rpm_repo_page}#{repo_link}/#{release_name}/$basearch"
        }
      }
    }

    parse_product(
      config,
      'maxscale_ci',
      {},
      systems,
      { name: 'default', path: '' }
    )
  end

  def parse_maxscale_release(config)
    systems = {
      debian: {
        path: '',
        key: lambda { |version|
          if config['repo']['deb']['old_key_versions'].include?(version)
            config['repo']['deb']['old_key']
          else
            config['repo']['deb']['key']
          end
        }
      },
      rhel: {
        path: '',
        key: lambda { |version|
          if config['repo']['rpm']['old_key_versions'].include?(version)
            config['repo']['rpm']['old_key']
          else
            config['repo']['rpm']['key']
          end
        },
        repo_path: lambda { |repo_link, release_name|
          "#{config['repo']['rpm']['path']}#{repo_link}/#{release_name}/$basearch"
        }
      }
    }

    parse_product(
      config,
      'maxscale_release',
      {},
      systems
    )
  end

  def parse_mysql_debian_systems(config)
    release_regexp = %r{^mysql-(\d+\.?\d+(-[^\/]*)?)(\/?)$}
    debian = {
      path: '',
      repo_page: config['repo']['deb']['path'],
      key: ->(_version) { config['repo']['deb']['key'] },
      release_path: ->(repo_link) { "#{repo_link}/dists" },
      release_name: ->(release) { release },
      repo_path: lambda { |system, release_name, version|
        "deb #{config['repo']['deb']['path']}#{system} #{release_name} mysql-#{version}"
      }
    }

    repo_page = debian[:repo_page]
    subpath = debian[:path]
    release_path = debian[:release_path]
    product = 'mysql'

    @logger.info 'Configuring mysql for debian systems'
    config['platforms'].each do |system_name|
      next if system_type_by_system_name(system_name) != :debian

      @logger.info "Creating repository configuration for #{system_name}"
      repos = get_links(repo_page).select do |link|
        link.content =~ %r{^#{system_name}(\/?)$}
      end.each_with_object([]) do |link, repositories|
        repo_link = "#{subpath}/#{link[:href]}".gsub(%r{\/\/}, '/')

        get_links(repo_page, release_path.call(repo_link)).select do |repo_inner_link|
          dir_link?(repo_inner_link)
        end.each do |release_link|
          release_name = release_link.content.delete('/')
          get_links(repo_page, "#{release_path.call(repo_link)}/#{release_name}").each do |release_inner_link|
            next if (release_inner_link.content =~ release_regexp).nil?
            version = release_inner_link.content.match(release_regexp).captures.first
            repo_path = debian[:repo_path].call(system_name, release_name, version)
            repositories << {
              repo: repo_path,
              repo_key: debian[:key].call(release_name),
              platform_version: release_name,
              platform: system_name,
              product: product,
              version: version
            }
          end
        end
        repositories
      end

      break if repos.empty?
      repos.map { |repo| repo[:version] }.uniq.each do |version|
        FileUtils.mkdir_p("#{@directory}/#{system_name}")
        File.write(
          "#{@directory}/#{system_name}/#{version}.json",
          JSON.pretty_generate(repos.select { |repo| repo[:version] == version })
        )
      end
    end
  end

  def parse_mysql(config)
    rpm_release_regexp = %r{^mysql-(\d+\.?\d+)-community(\/?)$}

    systems = {
      rhel: {
        path: '',
        release_name: ->(release) { release.match(rpm_release_regexp).captures.first },
        repo_path: lambda { |repo_link, release_name|
          "#{config['repo']['rpm']['path']}#{repo_link}/#{release_name}/x86_64"
        }
      }
    }

    parse_product(
      config,
      'mysql',
      {
        viable_release_detector: lambda { |system_type, _system_info, link, _links|
          system_type != :debian && !(link.content =~ rpm_release_regexp).nil?
        }
      },
      systems
    )
    parse_mysql_debian_systems(config)
  end

  def system_type_by_system_name(system_name)
    case system_name
    when 'centos', 'sles', 'rhel', 'opensuse'
      :rhel
    when 'debian', 'ubuntu'
      :debian
    end
  end

  def execute
    return ARGUMENT_ERROR_RESULT unless configure_command
    @directory = Dir.mktmpdir(COMMAND_NAME)
    info_and_log("Writing intermediate results to #{@directory}")
    remainning_products = @products.dup
    @attempts.times do
      remainning_products = remainning_products.reject do |product|
        info_and_log("Generating repository configuration for #{product}")
        FileUtils.rm_rf("#{@directory}/.", secure: true)
        begin
          send("parse_#{product}".to_sym, @config[product])
        rescue StandardError => e
          error_and_log("#{product} was not generated. Try again.")
          error_and_log(e.message)
          error_and_log(e.backtrace.reverse.join("\n"))
          next
        end
        info_and_log("Copying generated configuration for #{product} to the repository.")
        product_name = PRODUCTS_DIR_NAMES[product]
        FileUtils.mkdir_p("#{@destination}/#{product_name}")
        FileUtils.rm_rf("#{@destination}/#{product_name}", secure: true)
        FileUtils.cp_r("#{@directory}/.", "#{@destination}/#{product_name}")
        true
      end
      break if remainning_products.empty?
    end
    print_summary(remainning_products)
    FileUtils.rm_rf(@directory)
    SUCCESS_RESULT
  end

  def print_summary(products_with_errors)
    info_and_log("\n--------\nSUMMARY:\n")
    @products.sort.each do |product|
      result = products_with_errors.include?(product) ? '-' : '+'
      info_and_log("  #{product}: #{result}")
    end
  end
end

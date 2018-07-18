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
  }.freeze
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
    info = <<-HELP

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
HELP
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

  # Send iformation about the error to the error stream
  def error_and_log_error(error)
    error_and_log(error.message)
    error_and_log(error.backtrace.reverse.join("\n"))
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
    @config = YAML.safe_load(File.read(config_path))
    @products = if @env.nodeProduct
                  unless PRODUCTS_DIR_NAMES.keys.include?(@env.nodeProduct)
                    show_error_and_help("Unknown product #{@env.nodeProduct}.\n"\
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
    true
  end

  # Get links on the specified page
  def get_links(repo_page, path = '/')
    uri = "#{repo_page}/#{path}"
    doc = Nokogiri::HTML(open(uri))
    doc.css('a')
  end

  # Links that look like directories from the list of all links
  # @param url [String] path to the site to be checked
  # @return [Array] possible link locations
  def get_directory_links(url)
    get_links(url).select do |link|
      dir_link?(link)
    end
  end

  # This method goes through the main page and finds releases that should be added to
  # the repository
  def find_viable_releases(repo_page)
    possible_releases = get_links(repo_page, '/').select do |link|
      dir_link?(link)
    end
    checked_releases = possible_releases.select do |link|
      begin
        links = get_links(repo_page, link[:href])
                  .map(&:content)
        yield(link, links)
      rescue StandardError => error
        error_and_log("Unable to get list of links for #{repo_page}/#{link[:href]}")
        error_and_log_error(error)
        false
      end
    end
    checked_releases.map(&:content).map do |text|
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

    lambdas[:result_handler]&.call(repos)

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

  def create_repo_maxscale(repo_page, systems, release, system, type)
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

  def parse_community(config)
    parse_product(config, 'community')
  end

  def parse_columnstore_old(config)
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
      name: 'default', path: ''
    )
  end

  def parse_maxscale(config)
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
      'maxscale',
      {},
      systems
    )
  end

  def system_type_by_system_name(system_name)
    case system_name
    when 'centos', 'sles', 'rhel', 'opensuse'
      :rhel
    when 'debian', 'ubuntu'
      :debian
    end
  end


  def parse_columnstore(config)
    releases = []
    releases.concat(parse_columnstore_rpm_repository(config['repo']['rpm']))
    releases.concat(parse_columnstore_deb_repository(config['repo']['deb']))
    write_repository(releases)
  end

  def parse_columnstore_rpm_repository(config)
    parse_repository(
      config['path'], config['key'], 'columnstore',
      save_as_field(:version),
      append_url(%w[yum]),
      split_rpm_platforms,
      save_as_field(:platform_version),
      append_url(%w[x86_64]),
      lambda do |release, _|
        release[:repo] = release[:url]
        release
      end
    )
  end

  def parse_columnstore_deb_repository(config)
    parse_repository(
      config['path'], config['key'], 'columnstore',
      save_as_field(:version),
      append_url(%w[repo]),
      extract_field(:platform, %r{^(\p{Alpha}+)\p{Digit}+\/?$}, true),
      append_url(%w[dists]),
      save_as_field(:platform_version),
      lambda do |release, _|
        release[:repo] = release[:repo_url]
        release
      end
    )
  end

  def parse_mysql(config)
    releases = []
    releases.concat(parse_mysql_rpm_repository(config['repo']['rpm']))
    releases.concat(parse_mysql_deb_repository(config['repo']['deb']))
    write_repository(releases)
  end

  def parse_mysql_deb_repository(config)
    parse_repository(
      config['path'], config['key'], 'mysql',
      append_url(%w[debian ubuntu], :platform, true),
      append_url(%w[dists]),
      save_as_field(:platform_version),
      extract_field(:version, %r{^mysql-(\d+\.?\d+(-[^\/]*)?)(\/?)$}),
      lambda do |release, _|
        release[:repo] = "deb #{release[:repo_url]} #{release[:platform]} mysql-#{release[:version]}"
        release
      end
    )
  end

  # Method parses MySQL repositories that correspond to the following scheme:
  # http://repo.mysql.com/yum/mysql-8.0-community/el/7/x86_64/
  def parse_mysql_rpm_repository(config)
    parse_repository(
      config['path'], config['key'], 'mysql',
      extract_field(:version, %r{^mysql-(\d+\.?\d+)-community(\/?)$}),
      split_rpm_platforms,
      save_as_field(:platform_version),
      append_url(%w[x86_64], :repo),
      lambda do |release, _|
        release[:repo] = release[:url]
        release
      end
    )
  end

  # Write all information about releases to the JSON documents
  def write_repository(releases)
    platforms = releases.map { |release| release[:platform] }.uniq
    platforms.each do |platform|
      FileUtils.mkdir_p("#{@directory}/#{platform}")
      releases_by_version = Hash.new { |hash, key| hash[key] = [] }
      releases.each do |release|
        next if release[:platform] != platform
        releases_by_version[release[:version]] << extract_release_fields(release)
      end
      releases_by_version.each_pair do |version, version_releases|
        File.write("#{@directory}/#{platform}/#{version}.json",
                   JSON.pretty_generate(version_releases))
      end
    end
  end

  STORED_KEYS = %i[repo repo_key platform platform_version product version].freeze
  # Extract only required fields from the passed release before writing it to the file
  def extract_release_fields(release)
    STORED_KEYS.each_with_object({}) do |key, sliced_hash|
      raise "Unable to find key #{key} in repository_configuration #{release}." unless release.key?(key)
      sliced_hash[key] = release[key]
    end
  end

  # Parse the repository and provide required configurations
  def parse_repository(base_url, key, product, *steps)
    # Recursively go through the site and apply steps on each level
    result = steps.reduce([{ url: base_url }]) do |releases, step|
      releases.each_with_object([]) do |release, next_releases|
        begin
          links = get_directory_links(release[:url])
        rescue OpenURI::HTTPError => error
          error_and_log("Unable to get information from link '#{release[:url]}', message: '#{error.message}'")
          next
        end
        next_releases.concat(apply_step_to_links(step, links, release))
      end
    end
    # Add repository key and product to all releases
    result.each do |release|
      release[:repo_key] = key
      release[:product] = product
    end
  end

  # Helper method that applies the specified step to the current release
  # @param step [Lambda] the executable lambda that should be applied here
  # @param links [Array] the list of elements got from the page
  # @param release [Hash] information about the release collected so far
  def apply_step_to_links(step, links, release)
    # Delegate creation of next releases to the lambda
    next_releases = step.call(release, links)
    next_releases = [next_releases] unless next_releases.is_a?(Array)
    # Merge processing results into a new array
    next_releases.map do |next_release|
      result = release.merge(next_release)
      if result.key?(:link)
        result[:url] = "#{release[:url]}#{next_release[:link][:href]}"
        result.delete(:link)
      end
      result[:url] += '/' unless result[:url].end_with?('/')
      result
    end
  end

  # Filter all links via regular expressions and then place captured first element as version
  # @param field [Symbol] name of the field to write result to
  # @param rexexp [RegExp] expression that should have first group designated to field extraction
  # @param save_path [Boolean] whether to save current path to the release or not
  def extract_field(field, regexp, save_path = false)
    lambda do |release, links|
      possible_releases = links.select do |link|
        link.content =~ regexp
      end
      possible_releases.map do |link|
        result = {
          link: link,
          field => link.content.match(regexp).captures.first
        }
        result[:repo_url] = "#{release[:url]}#{link[:href]}" if save_path
        result
      end
    end
  end

  RPM_PLATFORMS = {
    'el' => %w[centos rhel],
    'sles' => %w[sles],
    'centos' => %w[centos],
  }.freeze
  def split_rpm_platforms
    lambda do |release, links|
      link_names = links.map { |link| link.content.delete('/') }
      releases = []
      RPM_PLATFORMS.each_pair do |keyword, platforms|
        next unless link_names.include?(keyword)
        platforms.each do |platform|
          releases << {
            url: "#{release[:url]}#{keyword}/",
            platform: platform
          }
        end
      end
      releases
    end
  end

  # Save all values that present in current level as field contents
  # @param field [Symbol] field to save data to
  def save_as_field(field)
    lambda do |_, links|
      links.map do |link|
        {
          link: link,
          field => link.content.delete('/')
        }
      end
    end
  end

  # Append URL to the current search path, possibly saving it to the key
  # and saving it to repo_url for future use
  # @param paths [Array<String>] array of paths that should be checked for presence
  # @param key [Symbol] field to save data to
  # @param save_path [Boolean] whether to save path to :repo_url field or not
  def append_url(paths, key = nil, save_path = false)
    lambda do |release, links|
      link_names = links.map { |link| link.content.delete('/') }
      repositories = []
      paths.each do |path|
        next unless link_names.include?(path)
        repository = {
          url: "#{release[:url]}#{path}/"
        }
        repository[:repo_url] = "#{release[:url]}#{path}" if save_path
        repository[key] = path if key
        repositories << repository
      end
      repositories
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
        rescue StandardError => error
          error_and_log("#{product} was not generated. Try again.")
          error_and_log_error(error)
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

# frozen_string_literal: true

require 'open-uri'
require 'optparse'
require 'nokogiri'
require 'pp'
require 'tmpdir'
require 'json'
require 'fileutils'
require 'logger'
require 'workers'

require_relative 'base_command'

# The command generates the repository configuration
class GenerateProductRepositoriesCommand < BaseCommand
  CONFIGURATION_FILE = 'generate_repository_config.yaml'
  PRODUCTS_DIR_NAMES = {
    'columnstore' => 'columnstore',
    'mariadb' => 'mariadb',
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

  # rubocop:disable Metrics/MethodLength
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
  # rubocop:enable Metrics/MethodLength

  def initialize(args, env, default_logger)
    super(args, env, default_logger)
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

  def load_configuration_file
    config_path = @env.configuration_file || @env.find_configuration(CONFIGURATION_FILE)
    unless File.exist?(config_path)
      show_error_and_help("Unable to find configuration file: '#{config_path}'.")
      return false
    end
    info_and_log("Configuring repositories using configuration: '#{config_path}'.")
    @config = YAML.safe_load(File.read(config_path))
  end

  def determine_products_to_parse
    if @env.nodeProduct
      unless PRODUCTS_DIR_NAMES.key?(@env.nodeProduct)
        show_error_and_help("Unknown product #{@env.nodeProduct}.\n"\
                            "Known products: #{PRODUCTS_DIR_NAMES.keys.join(', ')}")
        return false
      end
      @products = [@env.nodeProduct]
    else
      @products = PRODUCTS_DIR_NAMES.keys
    end
    info_and_log("Configuring repositories for products: #{@products.join(', ')}.")
    true
  end

  def determine_number_of_attempts
    @attempts = if @env.attempts
                  @env.attempts.to_i
                else
                  3
                end
    info_and_log("The configuration will be attempted #{@attempts} times.")
  end

  def setup_destination_directory
    @destination = if @args.empty?
                     @env.configuration_path('repo.d')
                   else
                     @args.first
                   end
    info_and_log("Repository configuration will be written to '#{@destination}'.")
  end

  # Use data provided via constructor to configure the command.
  def configure_command
    load_configuration_file
    return false unless determine_products_to_parse
    determine_number_of_attempts
    setup_destination_directory
    @maxscale_ci = @env.maxscale_ci
    Workers.pool.resize(10)
    true
  end

  # Links that look like directories from the list of all links
  # @param url [String] path to the site to be checked
  # @return [Array] possible link locations
  # rubocop:disable Security/Open
  def get_directory_links(url)
    uri = url.gsub(%r{([^:])\/+}, '\1/')
    @logger.info("Loading URLs '#{uri}'")
    doc = Nokogiri::HTML(open(uri))
    all_links = doc.css('a')
    all_links.select do |link|
      dir_link?(link)
    end
  end
  # rubocop:enable Security/Open

  # Check that passed link is possibly a directory or not
  # @param link link to check
  # @return [Boolean] whether link is directory or not
  def dir_link?(link)
    link.content =~ %r{\/$} || link[:href] =~ %r{^(?!((http|https):\/\/|\.{2}|\/|\?)).*\/$}
  end

  def parse_maxscale_ci(config)
    releases = []
    releases.concat(parse_maxscale_ci_rpm_repository(config['repo']['rpm']))
    releases.concat(parse_maxscale_ci_deb_repository(config['repo']['deb']))
    write_repository(releases)
  end

  def parse_maxscale_ci_rpm_repository(config)
    parse_repository(
      config['path'], config['key'], 'maxscale_ci',
      save_as_field(:version),
      append_url(%w[mariadb-maxscale]),
      split_rpm_platforms,
      extract_field(:platform_version, %r{^(\p{Digit}+)\/?$}),
      append_url(%w[x86_64]),
      lambda do |release, _|
        release[:repo] = release[:url]
        release
      end
    )
  end

  def parse_maxscale_ci_deb_repository(config)
    parse_repository(
      config['path'], config['key'], 'maxscale_ci',
      save_as_field(:version),
      append_url(%w[mariadb-maxscale]),
      append_url(%w[debian ubuntu], :platform, true),
      append_url(%w[dists]),
      save_as_field(:platform_version),
      lambda do |release, _|
        release[:repo] = "#{release[:repo_url]} #{release[:platform_version]} main"
        release
      end
    )
  end

  def parse_maxscale(config)
    releases = []
    releases.concat(parse_maxscale_rpm_repository(config['repo']['rpm']))
    releases.concat(parse_maxscale_deb_repository(config['repo']['deb']))
    write_repository(releases)
  end

  def parse_maxscale_rpm_repository(config)
    parse_repository(
      config['path'], config['key'], 'maxscale',
      save_as_field(:version),
      split_rpm_platforms,
      extract_field(:platform_version, %r{^(\p{Digit}+)\/?$}),
      append_url(%w[x86_64]),
      lambda do |release, _|
        release[:repo] = release[:url]
        release
      end
    )
  end

  def parse_maxscale_deb_repository(config)
    parse_repository(
      config['path'], config['key'], 'maxscale',
      save_as_field(:version),
      append_url(%w[debian ubuntu], :platform, true),
      append_url(%w[dists]),
      save_as_field(:platform_version),
      lambda do |release, _|
        release[:repo] = "#{release[:repo_url]} #{release[:platform_version]} main"
        release
      end
    )
  end

  def parse_mdbe(config)
    releases = []
    releases.concat(parse_mdbe_rpm_repository(config['repo']['rpm']))
    releases.concat(parse_mdbe_deb_repository(config['repo']['deb']))
    write_repository(releases)
  end

  def parse_mdbe_rpm_repository(config)
    parse_repository(
      config['path'], config['key'], 'mdbe',
      extract_field(:version, %r{^(\p{Digit}+\.\p{Digit}+)\/?$}),
      append_url(%w[yum]),
      save_as_field(:platform),
      extract_field(:platform_version, %r{^(\p{Digit}+)\/?$}),
      append_url(%w[x86_64]),
      lambda do |release, _|
        release[:repo] = release[:url]
        release
      end
    )
  end

  def parse_mdbe_deb_repository(config)
    parse_repository(
      config['path'], config['key'], 'mdbe',
      extract_field(:version, %r{^(\p{Digit}+\.\p{Digit}+)\/?$}),
      append_url(%w[repo]),
      append_url(%w[debian ubuntu], :platform, true),
      append_url(%w[dists]),
      save_as_field(:platform_version),
      lambda do |release, _|
        release[:repo] = "#{release[:repo_url]} #{release[:platform_version]} main"
        release
      end
    )
  end

  def parse_galera(config)
    releases = []
    version_regexp = %r{^(\p{Digit}+\.\p{Digit}+)\-galera\/?$}
    releases.concat(parse_mariadb_rpm_repository(config['repo']['rpm'], 'galera', version_regexp))
    releases.concat(parse_mariadb_deb_repository(config['repo']['deb'], 'galera', version_regexp))
    write_repository(releases)
  end

  def parse_mariadb(config)
    releases = []
    version_regexp = %r{^(\p{Digit}+\.\p{Digit}+)\/?$}
    releases.concat(parse_mariadb_rpm_repository(config['repo']['rpm'], 'mariadb', version_regexp))
    releases.concat(parse_mariadb_deb_repository(config['repo']['deb'], 'mariadb', version_regexp))
    write_repository(releases)
  end

  def parse_mariadb_rpm_repository(config, product, version_regexp)
    parse_repository(
      config['path'], config['key'], product,
      extract_field(:version, version_regexp),
      append_url(%w[centos rhel sles], :platform),
      extract_field(:platform_version, %r{^(\p{Digit}+)\/?$}),
      append_url(%w[x86_64]),
      lambda do |release, _|
        release[:repo] = release[:url]
        release
      end
    )
  end

  def parse_mariadb_deb_repository(config, product, version_regexp)
    parse_repository(
      config['path'], config['key'], product,
      extract_field(:version, version_regexp),
      save_as_field(:platform, true),
      append_url(%w[dists]),
      save_as_field(:platform_version),
      lambda do |release, _|
        release[:repo] = "#{release[:repo_url]} #{release[:platform_version]} main"
        release
      end
    )
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
        release[:repo] = "deb #{release[:repo_url]} #{release[:platform_version]} mysql-#{release[:version]}"
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
      next_releases = Workers.map(releases) do |release|
        begin
          links = get_directory_links(release[:url])
        rescue OpenURI::HTTPError, SocketError, Net::OpenTimeout => error
          error_and_log("Unable to get information from link '#{release[:url]}', message: '#{error.message}'")
          next
        end
        apply_step_to_links(step, links, release)
      end
      next_releases.flatten.reject(&:nil?)
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
    'rhel' => %w[rhel]
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
  # @param save_path [Boolean] whether to save path to :repo_url field or not
  def save_as_field(field, save_path = false)
    lambda do |release, links|
      links.map do |link|
        result = {
          link: link,
          field => link.content.delete('/')
        }
        result[:repo_url] = "#{release[:url]}#{link[:href]}" if save_path
        result
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

  # Create repository
  def create_repository(product)
    info_and_log("Generating repository configuration for #{product}")
    FileUtils.rm_rf("#{@directory}/.", secure: true)
    begin
      send("parse_#{product}".to_sym, @config[product])
    rescue StandardError => error
      error_and_log("#{product} was not generated. Try again.")
      error_and_log_error(error)
      return false
    end
    info_and_log("Copying generated configuration for #{product} to the repository.")
    product_name = PRODUCTS_DIR_NAMES[product]
    FileUtils.mkdir_p("#{@destination}/#{product_name}")
    FileUtils.rm_rf("#{@destination}/#{product_name}", secure: true)
    FileUtils.cp_r("#{@directory}/.", "#{@destination}/#{product_name}")
    true
  end

  # Print summary information about the created products
  # @param products_with_errors [Array<String>] product names that were not generated
  def print_summary(products_with_errors)
    info_and_log("\n--------\nSUMMARY:\n")
    @products.sort.each do |product|
      result = products_with_errors.include?(product) ? '-' : '+'
      info_and_log("  #{product}: #{result}")
    end
  end

  # Starting point of the application
  def execute
    return ARGUMENT_ERROR_RESULT unless configure_command
    @directory = Dir.mktmpdir(COMMAND_NAME)
    info_and_log("Writing intermediate results to #{@directory}")
    remainning_products = @products.dup
    @attempts.times do
      remainning_products = remainning_products.reject do |product|
        create_repository(product)
      end
      break if remainning_products.empty?
    end
    print_summary(remainning_products)
    FileUtils.rm_rf(@directory)
    SUCCESS_RESULT
  end
end

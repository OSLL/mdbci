# frozen_string_literal: true

# Class represents the MDBCI configuration on the hard drive.
class Configuration
  attr_reader :path

  # Checks whether provided path is a directory containing configurations.
  #
  # @param path [String] path that should be checked
  #
  # @returns [Boolean]
  def self.config_directory?(path)
    !path.nil? &&
      !path.empty? &&
      Dir.exist?(path) &&
      File.exist?("#{path}/template") &&
      File.exist?("#{path}/provider") &&
      File.exist?("#{path}/Vagrantfile")
  end

  # Method parses configuration/node specification and extracts path to the
  # configuration and node name if specified.
  #
  # @param spec [String] specification of configuration to parse
  # @raise [ArgumentError] if path to the configuration is invalid
  # @return configuration and node name. Node name is empty if not found in spec.
  def self.parse_spec(spec)
    # Separating config_path from node
    paths = spec.split('/') # Split path to the configuration
    config_path = paths[0, paths.length - 1].join('/')
    if config_directory?(config_path)
      node = paths.last
    else
      node = ''
      config_path = spec
    end
    [Configuration.new(config_path), node]
  end

  def initialize(path)
    raise ArgumentError, "Invalid path to the MDBCI configuration: #{path}" unless self.class.config_directory?(path)
    @path = File.absolute_path(path)
  end
end

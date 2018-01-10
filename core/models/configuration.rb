# frozen_string_literal: true

# Class represents the MDBCI configuration on the hard drive.
class Configuration
  attr_reader :path, :provider, :template

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
    @provider = read_provider(@path)
    @template = read_template(@path)
  end

  # Provide a list of nodes that are defined in the configuration
  # @return [Array<String>] names of the nodes.
  def node_names
    @template.select do |_, value|
      value.instance_of?(Hash)
    end.keys
  end

  private

  # Read node provider specified in the configuration.
  #
  # @return [String] name of the provider specified in the file.
  # @raise ArgumentError if there is no file or invalid provider specified.
  def read_provider(config_path)
    provider_file_path = "#{config_path}/provider"
    unless File.exist?(provider_file_path)
      raise ArgumentError, "There is no provider configuration specified in #{config_path}."
    end
    provider = File.read(provider_file_path).strip
    if provider == 'mdbci'
      raise ArgumentError, 'You are using mdbci node template. Please generate valid one before running up command.'
    end
    provider
  end

  # Read template from the specified configuration.
  #
  # @param config_path [String] path to the configuration.
  # @returns [Hash] produced by parsing JSON.
  # @raise [ArgumentError] if there is an error during template configuration.
  def read_template(config_path)
    template_file_name_path = "#{config_path}/template"
    unless File.exist?(template_file_name_path)
      raise ArgumentError, "There is no template configuration specified in #{config_path}."
    end
    template_path = File.read(template_file_name_path)
    unless File.exist?(template_path)
      raise ArgumentError, "The template #{template_path} specified in #{template_file_name_path} does not exist."
    end
    JSON.parse(File.read(template_path))
  end
end

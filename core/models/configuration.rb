# frozen_string_literal: true

# Class represents the MDBCI configuration on the hard drive.
class Configuration
  attr_reader :path, :provider, :template, :template_path, :aws_keypair_name

  NETWORK_FILE_SUFFIX = '_network_config'
  AWS_KEYPAIR_NAME = 'maxscale.keypair_name'

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
    @template_path = read_template_path(@path)
    @template = read_template(@template_path)
    @aws_keypair_name = read_aws_keypair_name
  end

  # Provide a list of nodes that are defined in the configuration
  # @return [Array<String>] names of the nodes.
  def node_names
    @template.select do |_, value|
      value.instance_of?(Hash)
    end.keys
  end

  # Provide a path to the network settings configuration file.
  def network_settings_file
    "#{@path}#{NETWORK_FILE_SUFFIX}"
  end

  # Check whether configuration has the keypair name or not.
  def aws_keypair_name?
    @provider == 'aws' && @aws_keypair_name != ''
  end

  # Get the name of the configuration we are working with
  def name
    File.basename(@path)
  end

  # Get the names of the boxes specified for this configuration
  #
  # @param node_name [String] name of the node to get box name
  # @return [Array<String>] unique names of the boxes used in the configuration
  def box_names(node_name = '')
    return [@template[node_name]['box']] unless node_name.empty?
    node_names.map do |name|
      @template[name]['box']
    end.uniq
  end

  private

  # Read the aws key pair name from the corresponding file.
  # @return [String] name of the keypair or empty string.
  def read_aws_keypair_name
    keypair_file_path = "#{@path}/#{AWS_KEYPAIR_NAME}"
    return '' unless File.exist?(keypair_file_path)
    File.read(keypair_file_path).chomp
  end

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

  # Read template path from the configuration
  #
  # @param config_path [String] path to the configuration.
  # @returns [String] path to the template path
  # @raise [ArgumentError] if there is an error during the file read
  def read_template_path(config_path)
    template_file_name_path = "#{config_path}/template"
    unless File.exist?(template_file_name_path)
      raise ArgumentError, "There is no template configuration specified in #{config_path}."
    end
    File.read(template_file_name_path)
  end

  # Read template from the specified template path
  #
  # @param template_path [String] path to the template file
  # @raise [ArgumentError] if the file does not exist
  # @return [Hash] data from the template JSON file
  def read_template(template_path)
    raise ArgumentError, "The template #{template_path} does not exist." unless File.exist?(template_path)
    JSON.parse(File.read(template_path))
  end
end

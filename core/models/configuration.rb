# frozen_string_literal: true

# Class represents the MDBCI configuration on the hard drive.
class Configuration
  attr_reader :path, :provider, :template, :template_path, :aws_keypair_name, :labels, :node_names

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

  def initialize(spec, labels = nil)
    @path, node = parse_spec(spec)
    raise ArgumentError, "Invalid path to the MDBCI configuration: #{spec}" unless self.class.config_directory?(@path)

    @provider = read_provider(@path)
    @template_path = read_template_path(@path)
    @template = read_template(@template_path)
    @aws_keypair_name = read_aws_keypair_name
    @labels = labels.nil? ? [] : labels.split(',')
    @node_names = select_node_names(node)
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

    @node_names.map do |name|
      @template[name]['box']
    end.uniq
  end

  private

  # Method parses configuration/node specification and extracts path to the
  # configuration and node name if specified.
  #
  # @param spec [String] specification of configuration to parse
  # @raise [ArgumentError] if path to the configuration is invalid
  # @return configuration and node name. Node name is empty if not found in spec.
  def parse_spec(spec)
    # Separating config_path from node
    paths = spec.split('/') # Split path to the configuration
    config_path = paths[0, paths.length - 1].join('/')
    if self.class.config_directory?(config_path)
      node = paths.last
    else
      node = ''
      config_path = spec
    end
    [File.absolute_path(config_path), node]
  end

  # Selects relevant node names based on information provided to constructor
  #
  # @param node [String] specific node
  # @return [Array<String>] list of relevant node names
  def select_node_names(node)
    return [node] unless node.empty?
    return select_nodes_by_label unless @labels.empty?

    @template.select do |_, value|
      value.instance_of?(Hash)
    end.keys
  end

  # Select nodes from the template file that have given labels
  #
  # @param desired_labels [Array<String>] list of node labels
  # @return [Array<String>] list of nodes matching given labels
  def select_nodes_by_label
    is_labels_set = false
    node_names = @template.select do |_, node_configuration|
      next unless node_configuration.instance_of?(Hash) && node_configuration['labels']

      is_labels_set = true
      @labels.any? do |desired_label|
        node_configuration['labels'].include?(desired_label)
      end
    end.keys
    raise(ArgumentError, 'Labels were not set in the template file') unless is_labels_set

    raise(ArgumentError, "Unable to find nodes matching labels: #{desired_labels.join(', ')}") if node_names.empty?

    node_names
  end

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

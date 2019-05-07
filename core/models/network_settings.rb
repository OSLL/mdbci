# frozen_string_literal: true

require 'iniparse'

# Class provides access to the configuration of machines
class NetworkSettings
  def self.from_file(path)
    document = IniParse.parse(File.read(path))
    settings = parse_document(document)
    NetworkSettings.new(settings)
  end

  def initialize(settings = {})
    @settings = settings
  end

  def add_network_configuration(name, settings)
    @settings[name] = settings
  end

  def node_settings(name)
    @settings[name]
  end

  # Provide configuration in the form of the configuration hash
  def as_hash
    @settings.each_with_object({}) do |(name, config), result|
      config.each_pair do |key, value|
        result["#{name}_#{key}"] = value
      end
    end
  end

  # Provide configuration in the form of the biding
  def as_binding
    result = binding
    as_hash.merge(ENV).each_pair do |key, value|
      result.local_variable_set(key.downcase.to_sym, value)
    end
    result
  end

  private

  # Parse INI document into a set of machine descriptions
  def self.parse_document(document)
    section = document['__anonymous__']
    options = section.enum_for(:each)
    names = options.map(&:key)
                   .select { |key| key.include?('_network') }
                   .map { |key| key.sub('_network', '') }
    configs = Hash.new { |hash, key| hash[key] = {} }
    names.each do |name|
      parameters = options.select { |option| option.key.include?(name) }
      parameters.reduce(configs) do |_result, option|
        key = option.key.sub(name, '').sub('_', '')
        configs[name][key] = option.value.sub(/^"/, '').sub(/"$/, '')
      end
    end
    configs
  end
end

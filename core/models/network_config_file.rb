# frozen_string_literal: true

require 'iniparse'
require 'ostruct'

# Class provides access to the configuration of machines
class NetworkConfigFile
  attr_reader :configs

  # @param config [String] path to the configuration file in ini format
  def initialize(config)
    document = IniParse.parse(File.read(config))
    @configs = parse_document(document)
  end

  # Provide configuration in the form of the configuration hash
  def environment_hash
    @configs.each_with_object({}) do |(name, config), result|
      config.each_pair do |key, value|
        result["#{name}_#{key}"] = value
      end
    end
  end

  # Provide configureation in the form of the biding
  def environment_binding
    result = binding
    environment_hash.merge(ENV).each_pair do |key, value|
      result.local_variable_set(key.downcase.to_sym, value)
    end
    result
  end

  private

  # Parse INI document into a set of machine descriptions
  def parse_document(document)
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
# Class for load configuration from YAML-config file
module Config
  require 'yaml'

  def self.parse(config_file_name, products_names = [])
    check_config_file(config_file_name)
    products = YAML.safe_load(File.read(config_file_name))
    check_config_content(products, products_names)
    products
  end

  private

  def self.check_config_file(file_name)
    return if !file_name.nil? || File.file?(file_name)
    raise IncorrectConfigFile, "Config file is not exist"
  end

  def self.check_config_content(config, products_names)
    not_included_products = products_names - config.keys
    return if not_included_products.empty?

    raise IncorrectConfigFile, "The config file does not contain "\
                               "information about products "\
                               "#{not_included_products}"
  end

  class IncorrectConfigFile < StandardError
    def initialize(msg = "Incorrect config file")
      super
    end
  end
end

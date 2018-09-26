require 'fileutils'
require 'tmpdir'
require 'xdg'
require 'yaml'

# The class represents the tool configuration that can be read from the
# hard drive, modified and then stored on the hard drive.
class ToolConfiguration
  def initialize(config = {})
    @config = config
  end

  CONFIG_FILE_NAME='mdbci/config.yaml'

  # Load configuration file from the disk and create ToolConfiguration file
  # @return [ToolConfiguration] read from the file
  def self.load
    XDG['CONFIG'].each do |config_dir|
      path = File.expand_path(CONFIG_FILE_NAME, config_dir)
      next unless File.exist?(path)
      return ToolConfiguration.new(YAML.load(File.read(path)))
    end
    return ToolConfiguration.new
  end

  # Stores current state of the configuration in the file
  def save
    Dir.mktmpdir do |directory|
      file = File.new("#{directory}/new-config.yaml", 'w')
      file.write(YAML.dump(@config))
      file.close
      config_file = File.expand_path(CONFIG_FILE_NAME, XDG['CONFIG_HOME'].to_s)
      FileUtils.cp(file.path, config_file)
    end
  end

  # A proxy method to provide access to the values of underlying hash object
  def [](key)
    @config[key]
  end

  # A proxy method to set values on the underlying hash object
  def []=(key, value)
    @config[key] = value
  end
end

# frozen_string_literal: true

require_relative 'shell_commands'
require 'time'

# This module provides methods to retrieve the version of MDBCI tool
module Version
  BUNDLED_VERSION_FILE = 'version'

  # Get the version of the tool
  # @param mdbci_directory [String] path to the directory where the version file lies, the MDBCI directory
  # @param logger [Out] the logger
  # @returns [String] version of the tool
  def self.version(mdbci_directory, logger)
    version_file = File.join(mdbci_directory, BUNDLED_VERSION_FILE)
    return File.read(version_file).strip if File.exist?(version_file)
    unless Dir.exist?(File.join(mdbci_directory, '.git'))
      return 'The MDBCI directory is not Git repository can not determine version'
    end

    result = ShellCommands.run_command_in_dir(logger, 'git rev-parse HEAD', mdbci_directory, false)
    "#{result[:output].strip}, #{Time.now.strftime('%Y-%m-%d')}"
  end
end

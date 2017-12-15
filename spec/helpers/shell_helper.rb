# frozen_string_literal: true

require_relative 'command_result'

# Module provides methods to test the execution of shell-commands
module ShellHelper
  TEMPLATE_FOLDER = File.absolute_path('spec/configs/template').freeze
  MDBCI_EXECUTABLE = './mdbci'

  # Create the configuration in directory with specified template.
  #
  # @param directory [String] path to the directory that should be used.
  # @param template [String] name of the template in template folder to use.
  # @return [String] path to the created configuration
  # @raise [RuntimeError] if the command execution has failed.
  def mdbci_create_configuration(directory, template)
    template_file = "#{TEMPLATE_FOLDER}/#{template}.json"
    target_directory = "#{directory}/#{template}"
    result = mdbci_command("generate --template #{template_file} #{target_directory}")
    raise "Unable to create config from template #{template}\n#{result}" unless result.success?
    target_directory
  end

  # Run mdbci command and return the exit code of the application.
  # @param command [String] command that should be run.
  # @return [Process::Status] result of executing the command.
  def mdbci_command(command)
    CommandResult.for_command("#{MDBCI_EXECUTABLE} #{command}")
  end
end

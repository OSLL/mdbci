# frozen_string_literal: true

require 'fileutils'
require 'models/command_result'
require_relative 'logger_helper'

# Module provides methods to test the execution of shell-commands.
module ShellHelper
  TEMPLATE_FOLDER = File.absolute_path('spec/configs/template').freeze
  MDBCI_EXECUTABLE = './mdbci'

  include LoggerHelper

  # Create the configuration in directory with specified template.
  #
  # @param directory [String] path to the directory that should be used.
  # @param template [String] name of the template in template folder to use.
  # @return [String] path to the created configuration
  # @raise [RuntimeError] if the command execution has failed.
  def mdbci_create_configuration(directory, template)
    logger.info("Generating configuration for template #{template}")
    template_source = "#{TEMPLATE_FOLDER}/#{template}.json"
    template_file = "#{directory}/#{template}.json"
    FileUtils.cp(template_source, template_file)
    target_directory = "#{directory}/#{template}"
    mdbci_check_command("generate --template #{template_file} #{target_directory}")
    target_directory
  end

  # Run mdbci command and return the exit code of the application.
  #
  # @param command [String] command that should be run.
  # @param options [Hash] list of options to pass to Open3 library
  # @return [CommandResult] result of executing the command.
  def mdbci_run_command(command, options = {})
    mdbci_command = "#{MDBCI_EXECUTABLE} #{command}"
    logger.info("Running mdbci command: '#{mdbci_command}'")
    result = CommandResult.for_command(mdbci_command, options)
    logger.debug(result.to_s)
    result
  end

  # Run mdbci command, check for the status of the exit code. If the command
  # does not succeed, raise an exception.
  #
  # @param command [String] command that should be run.
  # @param options [Hash] list of options to pass to Open3 library
  # @return [CommandResult] result of executing the command.
  # @raise [RuntimeError] if the command execution has failed.
  def mdbci_check_command(command, options = {})
    result = mdbci_run_command(command, options)
    raise "Unable to execute command: #{result}" unless result.success?
    result
  end

  # Run arbitrary command.
  #
  # @param command [String] command to run.
  # @param options [Hash] options to pass to open3 command.
  # @return [CommandResult] result of running the command.
  def run_command(command, options = {})
    logger.info("Running command '#{command}'")
    result = CommandResult.for_command(command, options)
    logger.debug(result.to_s)
    result
  end

  # Run arbitrary command in the specified directory.
  #
  # @param command [String] command that should be run.
  # @param directory [String] directory to go to.
  # @return [CommandResult] result of running the command.
  def run_command_in_dir(command, directory)
    logger.info("Running command '#{command}' in directory '#{directory}'")
    result = CommandResult.for_command(command, { chdir: directory })
    logger.debug(result.to_s)
    result
  end
end

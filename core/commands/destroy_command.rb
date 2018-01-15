# frozen_string_literal: true

require_relative 'base_command'
require_relative '../models/configuration'
require_relative '../helpers/shell_commands'
require 'fileutils'

# Command allows to destroy the whole configuration or a specific node.
class DestroyCommand < BaseCommand
  include ShellCommands

  def self.synopsis
    'Destroy configuration with all artefacts or a node'
  end

  # Method checks that all required parameters are passed to the command.
  # If not, it raises error.
  #
  # @raise [ArgumentError] if parameters are not valid.
  # @return [Configuration, String] parsed configuration.
  def setup_command
    if @args.empty? || @args.first.nil?
      show_help
      raise ArgumentError, 'Please specify path to the mdbci configuration on configuration/node as a parameter.'
    end
    Configuration.parse_spec(@args.first)
  end

  # Print brief instructions on how to use the command.
  def show_help
    info = <<-HELP
'destroy' command allows to destroy nodes and accompanying data.

You can either destroy a single node: mdbci destroy configuration/node
Or you can destroy all nodes: mdbci destroy configuration
In the latter case the command will remove the configuration folder
and network information file.
HELP
    @ui.out(info)
  end

  # Remove all files from the file system that correspond with the configuration.
  #
  # @param configuration [Configuration] that we are deling with.
  def remove_files(configuration)
    @ui.info("Removing configuration directory #{configuration.path}")
    FileUtils.rm_rf(configuration.path)
    @ui.info("Removing network settings file #{configuration.network_settings_file}")
    FileUtils.rm_f(configuration.network_settings_file)
  end

  # Stop machines specified in the configuration or in a node
  #
  # @param configuration [Configuration] that we operate on
  # @param node [String] node of the name to operate on
  def stop_machines(configuration, node)
    @ui.info 'Checking that machine is running'
    result = check_command_in_dir("vagrant status #{node}",
                                  configuration.path,
                                  "Vagrant was unable to find #{node}")
    return unless result[:output] =~ /#{node}\s*running/
    @ui.info 'Destroying the machines using vagrant'
    check_command_in_dir("vagrant destroy -f #{node}",
                         configuration.path,
                         'Vagrant was unable to destroy existing nodes')
  end

  def execute
    configuration, node = setup_command
    stop_machines(configuration, node)
    remove_files(configuration) if node.empty?
    SUCCESS_RESULT
  end
end

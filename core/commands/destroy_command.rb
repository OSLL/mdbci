# frozen_string_literal: true

require_relative 'base_command'
require_relative '../models/configuration'
require_relative '../models/command_result.rb'
require_relative '../services/shell_commands'
require_relative 'partials/docker_swarm_cleaner'
require_relative 'partials/vagrant_cleaner'

require 'fileutils'

# Command allows to destroy the whole configuration or a specific node.
class DestroyCommand < BaseCommand
  include ShellCommands

  def self.synopsis
    'Destroy configuration with all artefacts or a single node.'
  end

  # Method checks the parameters that were passed to the application.
  #
  # @return [Boolean] whether parameters are good or not.
  def check_parameters
    if !@env.list && !@env.node_name && (@args.empty? || @args.first.nil?)
      @ui.error 'Please specify the node name or path to the mdbci configuration or configuration/node as a parameter.'
      show_help
      false
    else
      true
    end
  end

  # Print brief instructions on how to use the command.
  # rubocop:disable Metrics/MethodLength
  def show_help
    info = <<-HELP
'destroy' command allows to destroy nodes and configuration data.

You can either destroy a single node:
  mdbci destroy configuration/node

Or you can destroy all nodes:
  mdbci destroy configuration

In the latter case the command will remove the configuration folder,
the network configuration file and the template. You can prevent
destroy command from deleting the template file:
  mdbci destroy configuration --keep_template

The command also deletes AWS key pair for corresponding configurations.

After running the vagrant destroy this command also deletes the
libvirt and VirtualBox boxes using low-level commands.

For the Docker-based configuration only the destruction of the whole configuration is supported.

You can destroy nodes by name without the need for configuration file.
As a name you can use any part of node name or regular expression:
  mdbci destroy --node-name name

You can view a list of all the virtual machines of all providers:
  mdbci destroy --list

Specifies the list of desired labels. It allows to filter VMs based on the label presence.
You can specify the list of labels to initiate destruction of virtual machines with those labels:
  mdbci destroy --labels [string]
If any of the labels passed to the command match any label in the machine description, then this
machine will be brought up and configured according to its configuration.
Labels should be separated with commas, do not contain any whitespaces.
    HELP
    @ui.out(info)
  end
  # rubocop:enable Metrics/MethodLength

  # Remove all files from the file system that correspond with the configuration.
  #
  # @param configuration [Configuration] that we are deling with.
  # @param keep_template [Boolean] whether to remove template or not.
  def remove_files(configuration, keep_template)
    @ui.info("Removing configuration directory #{configuration.path}")
    FileUtils.rm_rf(configuration.path)
    @ui.info("Removing network settings file #{configuration.network_settings_file}")
    FileUtils.rm_f(configuration.network_settings_file)
    @ui.info("Removing label information file #{configuration.labels_information_file}")
    FileUtils.rm_f(configuration.labels_information_file)
    return if keep_template

    @ui.info("Removing template file #{configuration.template_path}")
    FileUtils.rm_f(configuration.template_path)
  end

  # Handle cases when command calling with --list or --node-name options.
  def destroy_by_node_name
    vagrant_cleaner = VagrantCleaner.new(@env, @ui)
    vagrant_cleaner.destroy_nodes_by_name
  end

  # Handle case when command calling with configuration.
  def destroy_by_configuration
    configuration = Configuration.new(@args.first, @env.labels)
    if configuration.docker_configuration?
      docker_cleaner = DockerSwarmCleaner.new(@env, @ui)
      docker_cleaner.destroy_stack(configuration)
      remove_files(configuration, @env.keep_template)
    else
      vagrant_cleaner = VagrantCleaner.new(@env, @ui)
      vagrant_cleaner.destroy_nodes_by_configuration(configuration)
      return unless @env.labels.nil? && Configuration.config_directory?(@args.first)

      remove_files(configuration, @env.keep_template)
      vagrant_cleaner.destroy_aws_keypair(configuration)
    end
  end

  def execute
    return ARGUMENT_ERROR_RESULT unless check_parameters

    @aws_service = @env.aws_service
    if @env.node_name || @env.list
      destroy_by_node_name
    else
      destroy_by_configuration
    end
    SUCCESS_RESULT
  end
end

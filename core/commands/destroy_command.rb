# frozen_string_literal: true

require_relative 'base_command'
require_relative '../models/configuration'
require_relative '../models/command_result.rb'
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
HELP
    @ui.out(info)
  end

  # Remove all files from the file system that correspond with the configuration.
  #
  # @param configuration [Configuration] that we are deling with.
  # @param keep_template [Boolean] whether to remove template or not.
  def remove_files(configuration, keep_template)
    @ui.info("Removing configuration directory #{configuration.path}")
    FileUtils.rm_rf(configuration.path)
    @ui.info("Removing network settings file #{configuration.network_settings_file}")
    FileUtils.rm_f(configuration.network_settings_file)
    return if keep_template
    @ui.info("Removing template file #{configuration.template_path}")
    FileUtils.rm_f(configuration.template_path)
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

  # Destroy aws keypair specified in the configuration.
  #
  # @param configuration [Configuration] that we operate on.
  # @raise [RuntimeError] if there was an error during deletion of the key pair.
  def destroy_aws_keypair(configuration)
    return unless configuration.aws_keypair_name?
    @ui.info "Destroying AWS key pair #{configuration.aws_keypair_name}"
    result = CommandResult.for_command("aws ec2 delete-key-pair --key-name '#{configuration.aws_keypair_name}'")
    raise "Unable to delete AWS key pair #{configuration.aws_keypair_name}.\n#{result.messages}" unless result.success?
  end

  # Destroy the node if it was not destroyed by the vagrant.
  #
  # @param configuration [Configuration] configuration to use.
  # @param node [String] node name to destroy.
  def destroy_machine(configuration, node)
    case configuration.provider
    when 'libvirt'
      destroy_libvirt_domain(configuration, node)
    else
      @ui.error("Unknown provider #{configuration.provider}. Can not manually destroy virtual machines.")
    end
  end

  # Destroy the libvirt domain.
  #
  # @param configuration [Configuration] configuration to use.
  # @param node [String] node name to destroy.
  def destroy_libvirt_domain(configuration, node)

  end

  def execute
    configuration, node = setup_command
    stop_machines(configuration, node)
    if node.empty?
      configuration.node_names each do |node_name|
        destroy_machine(configuration, node_name)
      end
      remove_files(configuration, @env.keep_template)
      destroy_aws_keypair(configuration)
    else
      destroy_machine(configuration, node)
    end
    SUCCESS_RESULT
  end
end

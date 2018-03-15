# frozen_string_literal: true

require_relative 'base_command'
require_relative '../models/configuration'
require_relative '../models/command_result.rb'
require_relative '../helpers/shell_commands'
require 'fileutils'

# Command allows to destroy the whole configuration or a specific node.
class DestroyCommand < BaseCommand
  include ShellCommands

  INSTANCE_NOT_FOUND = 'instance-not-found'

  def self.synopsis
    'Destroy configuration with all artefacts or a single node.'
  end

  # Method checks the parameters that were passed to the application.
  #
  # @return [Boolean] whether parameters are good or not.
  def check_parameters
    if @args.empty? || @args.first.nil?
      @ui.error 'Please specify path to the mdbci configuration or configuration/node as a parameter.'
      show_help
      false
    else
      true
    end
  end

  # Method checks that all required parameters are passed to the command.
  # If not, it raises error.
  #
  # @raise [ArgumentError] if parameters are not valid.
  # @return [Configuration, String] parsed configuration.
  def setup_command
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

After running the vagrant destroy this command also deletes the
libvirt and VirtualBox boxes using low-level commands.
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
    when 'virtualbox'
      destroy_virtualbox_machine(configuration, node)
    when 'aws'
      destroy_aws_machine(configuration, node)
    else
      @ui.error("Unknown provider #{configuration.provider}. Can not manually destroy virtual machines.")
    end
  end

  # Destroy the libvirt domain.
  #
  # @param configuration [Configuration] configuration to use.
  # @param node [String] node name to destroy.
  # rubocop:disable Metrics/MethodLength
  def destroy_libvirt_domain(configuration, node)
    domain_name = "#{configuration.name}_#{node}".gsub(/[^-a-z0-9_\.]/i, '')
    result = run_command_and_log("virsh domstats #{domain_name}")
    if !result[:value].success?
      @ui.info "Libvirt domain #{domain_name} has been destroyed, doing nothing."
      return
    end
    check_command("virsh destroy #{domain_name}",
                  "Unable to destroy domain #{domain_name}")
    result = check_command("virsh snapshot-list #{domain_name} --tree",
                           "Unable to get list of snapshots for #{domain_name}")
    result[:output].split('\n').each do |snapshot|
      next if snapshot.chomp.empty?
      check_command("virsh snapshot-delete #{domain_name} #{snapshot}",
                    "Unable to delete snapshot #{snapshot} for #{domain_name} domain")
    end
    check_command("virsh undefine #{domain_name}",
                  "Unable to undefine domain #{domain_name}")
  end
  # rubocop:enable Metrics/MethodLength

  # Destroy the virtualbox virtual machine.
  #
  # @param configuration [Configuration] configuration to user.
  # @param node [String] name of node to destroy.
  def destroy_virtualbox_machine(configuration, node)
    vbox_name = "#{configuration.name}_#{node}"
    result = run_command_and_log("VBoxManage showvminfo #{vbox_name}")
    if !result[:value].success?
      @ui.info "VirtualBox machine #{vbox_name} has been destroyed, doing notthing"
      return
    end
    check_command("VBoxManage controlvm #{vbox_name} poweroff",
                  "Unable to shutdown #{vbox_name} machine.")
    check_command("VBoxManage unregistervm #{vbox_name} -delete",
                  "Unable to delete #{vbox_name} machine.")
  end

  # Destroy the aws virtual machine.
  #
  # @param configuration [Configuration] configuration to user.
  # @param node [String] name of node to destroy.
  # rubocop:disable Metrics/MethodLength
  def destroy_aws_machine(configuration, node)
    aws_box_name = "#{configuration.name}_#{node}"
    if @aws_instance_ids.empty? || @aws_instance_ids[node].nil?
      @ui.error "Unable to terminate #{aws_box_name} machine. Instance id does not exist."
      return
    end
    aws_box_state = get_aws_instance_state_by_id(@aws_instance_ids[node])
    if aws_box_state == INSTANCE_NOT_FOUND
      @ui.error "Unable get state of #{aws_box_name} from AWS."
      return
    end
    if %w[stopping stopped shutting-down terminated].include?(aws_box_state)
      @ui.info "AWS machine #{aws_box_name} has been destroyed, doing notthing."
      return
    end
    check_command("aws ec2 terminate-instances --instance-ids #{@aws_instance_ids[node]} --profile mdbci",
                  "Unable to terminate #{aws_box_name} machine.")
  end
  # rubocop:enable Metrics/MethodLength

  def execute
    return ARGUMENT_ERROR_RESULT unless check_parameters
    configuration, node = setup_command
    remember_aws_instance_id(configuration, node)
    stop_machines(configuration, node)
    if node.empty?
      configuration.node_names.each do |node_name|
        destroy_machine(configuration, node_name)
      end
      remove_files(configuration, @env.keep_template)
      destroy_aws_keypair(configuration)
    else
      destroy_machine(configuration, node)
    end
    SUCCESS_RESULT
  end

  # Remember the instance id of aws virtual machine.
  #
  # @param configuration [Configuration] configuration to user.
  # @param node [String] name of node to remember.
  def remember_aws_instance_id(configuration, node)
    return if configuration.provider != 'aws'
    node_names = if node.empty?
                   configuration.node_names
                 else
                   [node]
                 end
    @aws_instance_ids = node_names.map do |node_name|
      [node_name, get_aws_instance_id_by_node_name(configuration, node_name)]
    end.to_h
  end

  # Read the instance id of aws virtual machine from local vagrant directory.
  #
  # @param configuration [Configuration] configuration to user.
  # @param node [String] name of node to read.
  # @return [String] id of the instance.
  def get_aws_instance_id_by_node_name(configuration, node)
    aws_instance_id_path = "#{configuration.path}/.vagrant/machines/#{node}/aws/id"
    return nil unless File.file?(aws_instance_id_path)
    File.read(aws_instance_id_path)
  end

  # Get the state of aws virtual machine instance from aws instances description by id.
  #
  # @param instance_id [String] aws virtual machine instance id.
  # @return [String] state of the instance or INSTANCE_NOT_FOUND constant.
  def get_aws_instance_state_by_id(instance_id)
    return INSTANCE_NOT_FOUND if instance_id.nil?
    instances_description = run_command_and_log('aws ec2 describe-instances --profile mdbci')[:output]
    instances_array = JSON.parse(instances_description).to_h
    instance = nil
    instances_array['Reservations'].find do |reservation|
      instance = reservation['Instances'].find do |current_instance|
        current_instance['InstanceId'] == instance_id
      end
    end
    return INSTANCE_NOT_FOUND if instance.nil?
    instance['State']['Name']
  end
end

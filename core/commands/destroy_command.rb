# frozen_string_literal: true

require_relative 'base_command'
require_relative '../models/configuration'
require_relative '../models/command_result.rb'
require_relative '../services/shell_commands'
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

You can destroy nodes by name without the need for configuration file.
As a name you can use any part of node name or regular expression:
  mdbci destroy --node-name name

You can view a list of all the virtual machines of all providers:
  mdbci destroy --list

Specifies the list of desired labels. It allows to filter VMs based on the label presence.
You can specify the list of labes to initiate destruction of virtual machines with those labels:
  mdbci destroy --labels [string]
If any of the labels passed to the command match any label in the machine description, then this machine will be brought up and configured according to its configuration.
Labels should be separated with commas, do not contain any whitespaces.
    HELP
    @ui.out(info)
  end
  # rubocop:enable Metrics/MethodLength

  # Method gets the libvirt virtual machines names list.
  #
  # @return [Array] virtual machines names.
  def libvirt_vm_list
    check_command('virsh list --name --all',
                  'Unable to get Libvirt vm\'s list')[:output].split("\n")
  end

  # Method gets the VirtualBox virtual machines names list.
  #
  # @return [Array] virtual machines names.
  def virtualbox_vm_list
    check_command('VBoxManage list vms | grep -o \'"[^\"]*"\' | tr -d \'"\'',
                  'Unable to get VirtualBox vm\'s list')[:output].split("\n")
  end

  # Method gets the AWS instances names list.
  #
  # @return [Array] instances names list.
  def aws_vm_list
    @aws_instance_ids.map { |instance| instance[:node_name] }
  end

  # Print virtual machines names list of all providers.
  def show_vm_list
    vm_list = libvirt_vm_list + virtualbox_vm_list + aws_vm_list
    @ui.info("Virtual machines list: #{vm_list}")
  end

  # Destroy all virtual machines of all providers that correspond with the node_name.
  #
  # @param node_name [String] regexp of the node name.
  def destroy_machine_by_name(node_name)
    node_name_regexp = Regexp.new(node_name)
    vm_list = { libvirt: libvirt_vm_list, virtualbox: virtualbox_vm_list, aws: aws_vm_list }
    vm_list.each do |provider, nodes|
      vm_list[provider] = nodes.select { |node| node =~ node_name_regexp }
    end
    @ui.info("Virtual machines to destroy: #{vm_list.values.flatten}")
    return unless @ui.prompt('Do you want to continue? [y/n]')[0].casecmp('y').zero?

    vm_list.each do |provider, nodes|
      nodes.each { |node| destroy_machine(nil, nil, provider.to_s, node) }
    end
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
  def stop_machines(configuration)
    @ui.info 'Destroying the machines using vagrant'
    check_command_in_dir("vagrant destroy -f #{configuration.node_names.join(' ')}",
                         configuration.path,
                         'Vagrant was unable to destroy existing nodes')
  end

  # Destroy aws keypair specified in the configuration.
  #
  # @param configuration [Configuration] that we operate on.
  def destroy_aws_keypair(configuration)
    return unless configuration.aws_keypair_name?

    @ui.info "Destroying AWS key pair #{configuration.aws_keypair_name}"
    @aws_service.delete_key_pair(configuration.aws_keypair_name)
  end

  # Destroy the node if it was not destroyed by the vagrant.
  # To destroy the nodes by name, use provider and vm_name params.
  #
  # @param configuration [Configuration] configuration to use.
  # @param node [String] node name to destroy.
  # @param provider [String] provider name of virtual machine.
  # @param vm_name [String] virtual machine name to destroy
  def destroy_machine(configuration, node, provider = nil, vm_name = nil)
    provider ||= configuration.provider
    case provider
    when 'libvirt'
      destroy_libvirt_domain(configuration, node, vm_name)
    when 'virtualbox'
      destroy_virtualbox_machine(configuration, node, vm_name)
    when 'aws'
      destroy_aws_machine(configuration, node, vm_name)
    else
      @ui.error("Unknown provider #{provider}. Can not manually destroy virtual machines.")
    end
  end

  # Destroy the libvirt domain.
  # To destroy the node by name, use domain_name param.
  #
  # @param configuration [Configuration] configuration to use.
  # @param node [String] node name to destroy.
  # @param domain_name [String] name of libvirt domain to destroy.
  # rubocop:disable Metrics/MethodLength
  def destroy_libvirt_domain(configuration, node, domain_name = nil)
    domain_name ||= "#{configuration.name}_#{node}".gsub(/[^-a-z0-9_\.]/i, '')
    result = run_command_and_log("virsh domstats #{domain_name}")
    if !result[:value].success?
      @ui.info "Libvirt domain #{domain_name} has been destroyed, doing nothing."
      return
    end
    check_command("virsh shutdown #{domain_name}",
                  "Unable to shutdown domain #{domain_name}")
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
    result = check_command("virsh -q vol-list --pool default | awk '{print $1}' | grep '^#{domain_name}'",
                           "Unable to get machine's volumes for #{domain_name}")
    result[:output].split('\n').each do |volume|
      next if volume.chomp.empty?

      check_command("virsh vol-delete --pool default #{volume}",
                    "Unable to delete volume #{volume} for #{domain_name} domain")
    end
  end
  # rubocop:enable Metrics/MethodLength

  # Destroy the virtualbox virtual machine.
  # To destroy the node by name, use vbox_name param.
  #
  # @param configuration [Configuration] configuration to user.
  # @param node [String] name of node to destroy.
  # @param vbox_name [String] name of virtual machine to destroy.
  def destroy_virtualbox_machine(configuration, node, vbox_name = nil)
    vbox_name ||= "#{configuration.name}_#{node}"
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
  # To destroy the node by name, use aws_box_name param.
  #
  # @param configuration [Configuration] configuration to user.
  # @param node [String] name of node to destroy.
  # @param aws_box_name [String] name of instance to destroy.
  def destroy_aws_machine(configuration, node, aws_box_name = nil)
    aws_box_name ||= "#{configuration.name}_#{node}"
    instance_id = get_aws_instance_id_by_node_name(aws_box_name)
    if instance_id.nil?
      @ui.error("Unable to terminate #{aws_box_name} machine. Instance id does not exist.")
      return
    end
    unless @aws_service.instance_running?(instance_id)
      @ui.info("AWS instance '#{instance_id}' for node '#{node}' is not running.")
    end
    @ui.info("Sending termination command for instance '#{instance_id}' used for node '#{node}.")
    @aws_service.terminate_instance(instance_id)
  end

  # Handle cases when command calling with --list or --node-name options.
  def manage_destroy_by_node_name
    remember_aws_instance_id
    if @env.list
      show_vm_list
    elsif @env.node_name
      destroy_machine_by_name(@env.node_name)
    end
  end

  # Handle case when command calling with configuration.
  def manage_destroy_by_configuration
    configuration = Configuration.new(@args.first, @env.labels)
    remember_aws_instance_id if configuration.provider == 'aws'
    stop_machines(configuration)
    configuration.node_names.each do |node_name|
      destroy_machine(configuration, node_name)
    end
    return unless @env.labels.nil? && Configuration.config_directory?(@args.first)

    remove_files(configuration, @env.keep_template)
    destroy_aws_keypair(configuration)
  end

  def execute
    return ARGUMENT_ERROR_RESULT unless check_parameters

    @aws_service = @env.aws_service
    if @env.node_name || @env.list
      manage_destroy_by_node_name
    else
      manage_destroy_by_configuration
    end
    SUCCESS_RESULT
  end

  # Remember the instance id of aws virtual machines.
  def remember_aws_instance_id
    @aws_instance_ids = @aws_service&.instances_list || []
  end

  # Read the instance id of aws virtual machine from local vagrant directory.
  #
  # @param node_name [String] name of instance.
  # @return [String] id of the instance.
  def get_aws_instance_id_by_node_name(node_name)
    found_instance = @aws_instance_ids.find { |instance| instance[:node_name] == node_name }
    found_instance.nil? ? nil : found_instance[:instance_id]
  end
end

# frozen_string_literal: true

require 'open3'
require_relative 'base_command'
require_relative '../constants'
require_relative '../services/shell_commands'

# Snapshot command allows to manage snapshots of virtual environments for configurations.
class SnapshotCommand < BaseCommand
  include ShellCommands

  SNAPSHOT_ACTION_REQUIRED = 'snapshot action is required (take, revert, delete, list)'

  PATH_TO_NODES_OPTION_REQUIRED = '--path-to-nodes option must be specified'
  SNAPSHOT_NAME_AND_NODE_NAME_OPTIONS_REQUIRED =
    '--node-name and --snapshot-name must be specified both or only --snapshot-name'
  NODE_NAME_OPTIONS_REQUIRED = '--node-name must be specified'

  NON_ZERO_BASH_EXIT_CODE_ERROR = 'command exited with non zero exit code'

  DOCKER_SNAPSHOT_NOT_FOUND = 'docker snapshot is not found'
  DOCKER_MACHINE_NOT_CREATED = 'docker machine is not created'
  DOCKER_SNAPSHOT_EXISTS = 'docker snapshot already exists'
  DOCKER_CONTAINER_ID_NOT_FOUND = 'docker container id not found'
  DOCKER_SNAPSHOT_INITIAL_OR_IN_USE_NO_DELETION = 'docker snapshot is initial or in use and could not be deleted'
  DOCKER_SNAPSHOT_NAME_MUST_BE_DOWNCASE = 'docker snapshot name will be converted to downcase'
  DOCKER_IMAGE_NAME_EXISTS =
    'docker snapshot name is an image name, and that name already exists (check with "docker images")'

  NODES_NOT_FOUND_ERROR = 'nodes are not found'
  SNAPSHOT_ALREADY_EXISTS = 'snapshot already exists'
  SNAPSHOT_NOT_EXISTS = 'snapshot does not exist'
  SNAPSHOTS_NOT_FOUND = 'snapshots does not exist for this node (create it with "snapshot take..." command)'

  HELP_OPTION = '--help'
  NODE_NAME_OPTION = '--node-name'
  PATH_TO_NODES_OPTION = '--path-to-nodes'
  SNAPSHOT_NAME_OPTION = '--snapshot-name'

  SNAPSHOT_GLOBAL_PREFIX = 'mdbci_snapshot'

  TEMPLATE_COOKBOOK_PATH = 'cookbook_path'
  TEMPLATE_AWS_CONFIG = 'aws_config'

  ACTION_TAKE = 'take'
  ACTION_REVERT = 'revert'
  ACTION_LIST = 'list'
  ACTION_REMOVE = 'remove'

  KNOWN_ACTIONS = [ACTION_TAKE, ACTION_REVERT, ACTION_LIST, ACTION_REMOVE].freeze

  attr_accessor :provider
  attr_accessor :path_to_nodes
  # @nodes is an array of nodes names
  attr_accessor :nodes
  attr_accessor :nodes_directory_name
  # @docker_container_ids is a hash -> { NODE_NAME => CONTAINER_ID }
  attr_accessor :node_name
  attr_accessor :snapshot_name

  def self.synopsis
    'Manage snapshots of configurations and nodes.'
  end

  # Parse all arguments and setup the command variables
  def setup_command
    @path_to_nodes = @env.path_to_nodes
    @node_name = @env.node_name
    @snapshot_name = @env.snapshot_name
    raise PATH_TO_NODES_OPTION_REQUIRED if @path_to_nodes.to_s.empty?
    @nodes_directory_name = @path_to_nodes.to_s.split('/')[-1]
    @provider = File.read("#{@path_to_nodes}/provider")
    @nodes = get_nodes
    @config = Configuration.new(@env.path_to_nodes)
  end

  # Parse arguments and get action name to perform.
  #
  # @raise [RuntimeError] if there are no arguments or unknown action was passed
  # @return [String] name of the action.
  def check_and_get_action
    raise SNAPSHOT_ACTION_REQUIRED if @args.empty?
    action = @args[0]
    raise "Unknown action '#{action}'" unless KNOWN_ACTIONS.include?(action)
    action
  end

  def execute
    setup_command
    action = check_and_get_action
    case action
    when ACTION_TAKE
      if !@node_name.to_s.empty? && !@snapshot_name.to_s.empty?
        take_snapshot(@node_name, @snapshot_name)
      elsif @node_name.to_s.empty? && !@snapshot_name.to_s.empty?
        take_snapshots(@snapshot_name)
      else
        raise SNAPSHOT_NAME_AND_NODE_NAME_OPTIONS_REQUIRED
      end
    when ACTION_REVERT
      if !@node_name.to_s.empty? && !@snapshot_name.to_s.empty?
        revert_snapshot(@node_name, @snapshot_name)
      elsif @node_name.to_s.empty? && !@snapshot_name.to_s.empty?
        revert_snapshots(@snapshot_name)
      else
        raise SNAPSHOT_NAME_AND_NODE_NAME_OPTIONS_REQUIRED
      end
    when ACTION_REMOVE
      if @node_name.to_s.empty? || @snapshot_name.to_s.empty?
        raise SNAPSHOT_NAME_AND_NODE_NAME_OPTIONS_REQUIRED
      end
      remove_snapshot(@node_name, @snapshot_name)
    when ACTION_LIST
      list_snapshots node_name
    end
    SUCCESS_RESULT
  end

  def get_nodes
    nodes = []
    template = JSON.parse(File.read(File.read("#{@path_to_nodes}/template")))
    template.each do |possible_node|
      if (possible_node[0] != TEMPLATE_AWS_CONFIG) && (possible_node[0] != TEMPLATE_COOKBOOK_PATH)
        nodes.push possible_node[0]
      end
    end
    raise NODES_NOT_FOUND_ERROR if nodes.empty?
    nodes
  end

  # Return hash like -> { node0 => id0, node1 => id1, ... }
  def get_docker_containers_ids
    container_ids = {}
    @nodes.each do |node_name|
      begin
        container_ids[node_name] = File.read("#{@path_to_nodes}/.vagrant/machines/#{node_name}/docker/id")
      rescue Errno::ENOENT
      end
    end
    container_ids
  end

  def get_docker_node_id(node_name)
    snapshot_information = JSON.parse(File.read("#{@path_to_nodes}/#{node_name}/snapshots"))
    snapshot_information[node_name]['id']
  end

  # Returns array of snapshots names
  def get_docker_snapshots(node_name)
    snapshot_information = JSON.parse(File.read("#{@path_to_nodes}/#{node_name}/snapshots"))
    snapshot_information[node_name]['snapshots']
  end

  # Adds snapshot to docker machine
  def add_docker_snapshot_information(node_name, snapshot_name)
    snapshot_information = JSON.parse(File.read("#{@path_to_nodes}/#{node_name}/snapshots"))
    snapshot_information[node_name]['snapshots'] << snapshot_name
    File.open("#{@path_to_nodes}/#{node_name}/snapshots", 'w') do |f|
      f.puts snapshot_information.to_json
    end
  end

  # Removes snapshot to docker machine
  def remove_docker_snapshot_information(node_name, snapshot_name)
    snapshot_information = JSON.parse(File.read("#{@path_to_nodes}/#{node_name}/snapshots"))
    snapshot_information[node_name]['snapshots'].delete snapshot_name
    puts snapshot_information[node_name]['snapshots']
    File.open("#{@path_to_nodes}/#{node_name}/snapshots", 'w') do |f|
      f.puts snapshot_information.to_json
    end
  end

  def get_docker_initial_snapshot(node_name)
    snapshots = JSON.parse(File.read("#{@path_to_nodes}/#{node_name}/snapshots"))
    snapshots[node_name]['initial_snapshot']
  end

  def get_docker_current_snapshot(node_name)
    snapshots = JSON.parse(File.read("#{@path_to_nodes}/#{node_name}/snapshots"))
    snapshots[node_name]['current_snapshot']
  end

  def change_current_docker_snapshot(node_name, snapshot_name)
    snapshots = get_docker_snapshots node_name
    raise "#{snapshot_name} #{DOCKER_SNAPSHOT_NOT_FOUND}" unless snapshots.include? snapshot_name
    snapshot_information = JSON.parse(File.read("#{@path_to_nodes}/#{node_name}/snapshots"))
    snapshot_information[node_name]['current_snapshot'] = snapshot_name
    File.open("#{@path_to_nodes}/#{node_name}/snapshots", 'w') do |f|
      f.puts snapshot_information.to_json
    end
  end

  # method returns bash command exit code
  def execute_bash(cmd, disable_stdout_output)
    output = []
    process_status = Open3.popen3(cmd) do |_, stdout, stderr, wait_thr|
      stdout.each do |line|
        @ui.info line unless disable_stdout_output
        output.push(line.chomp)
      end
      stderr.each { |line| @ui.error line }
      wait_thr.value
    end
    raise "#{cmd} #{NON_ZERO_BASH_EXIT_CODE_ERROR} #{process_status}" unless process_status.success?
    output
  end

  def get_docker_images
    run_reliable_command('docker images --format "{{.Repository}}"', log = false)[:output].strip
  end

  # args[0] node name
  # no arguments => all nodes
  def get_snapshots(node_name)
    raise NODE_NAME_OPTIONS_REQUIRED if node_name.to_s.empty?
    case @provider
    when LIBVIRT
      output = run_reliable_command("virsh -q snapshot-list --domain #{@nodes_directory_name}_#{node_name} | awk '{print $1}'",
                                    log = false)[:output].strip
      return output
    when DOCKER
      return get_docker_snapshots(node_name)
    else
      current_dir = Dir.pwd
      Dir.chdir @path_to_nodes
      output = run_reliable_command("vagrant snap list #{node_name} | grep +.* | awk '{print $2}'",
                                    log = false)[:output].strip
      Dir.chdir current_dir
      return output
    end
  end

  # args[0] node name
  # no arguments => all nodes
  def list_snapshots(node_name)
    puts get_snapshots node_name
  end

  def take_snapshot(node_name, snapshot_name)
    full_snapshot_name = "#{SNAPSHOT_GLOBAL_PREFIX}_#{snapshot_name}_#{@nodes_directory_name}_#{node_name}"
    @ui.info "Taking snapshot of #{node_name} to #{full_snapshot_name}"
    raise SNAPSHOT_ALREADY_EXISTS if get_snapshots(node_name).include? full_snapshot_name
    case @provider
    when LIBVIRT
      run_reliable_command("virsh snapshot-create-as --domain #{@nodes_directory_name}_#{node_name} --name #{full_snapshot_name}")
    when DOCKER
      raise DOCKER_IMAGE_NAME_EXISTS if get_docker_images.include? full_snapshot_name
      unless full_snapshot_name == full_snapshot_name.to_s.downcase
        @ui.warning DOCKER_SNAPSHOT_NAME_MUST_BE_DOWNCASE
        full_snapshot_name = full_snapshot_name.to_s.downcase
      end
      docker_containers_ids = get_docker_containers_ids
      raise "#{node_name} #{DOCKER_MACHINE_NOT_CREATED}" unless docker_containers_ids.include? node_name
      run_reliable_command("docker commit -p #{docker_containers_ids[node_name]} #{full_snapshot_name}")
      add_docker_snapshot_information(node_name, full_snapshot_name)
    else
      current_dir = Dir.pwd
      Dir.chdir @path_to_nodes
      run_reliable_command("vagrant snap take #{node_name} --name=#{full_snapshot_name}")
      Dir.chdir current_dir
    end
  end

  def take_snapshots(snapshot_name)
    get_nodes.each do |node_name|
      take_snapshot(node_name, snapshot_name)
    end
  end

  def ntp_service_name(node_name)
    box = @config.template[node_name]['box']
    (box.downcase =~ /(ubuntu|debian)/).nil? ? 'ntpd' : 'ntp'
  end

  def revert_snapshot(node_name, snapshot_name)
    full_snapshot_name = "#{SNAPSHOT_GLOBAL_PREFIX}_#{snapshot_name}_#{@nodes_directory_name}_#{node_name}"
    @ui.info "Reverting node #{node_name} to snapshot #{full_snapshot_name}"
    snapshots = get_snapshots(node_name)
    raise SNAPSHOTS_NOT_FOUND if snapshots.empty?
    raise SNAPSHOT_NOT_EXISTS unless snapshots.include? full_snapshot_name
    case @provider
    when LIBVIRT
      run_reliable_command("virsh snapshot-revert --domain #{@nodes_directory_name}_#{node_name} --snapshotname #{full_snapshot_name}")
      pwd = Dir.pwd
      Dir.chdir @path_to_nodes
      ntp_service = ntp_service_name(node_name)
      run_reliable_command("vagrant ssh #{node_name} -c '/usr/bin/sudo /bin/systemctl stop #{ntp_service}.service'")
      run_reliable_command("vagrant ssh #{node_name} -c '/usr/bin/sudo sntp -s  0.europe.pool.ntp.org'")
      run_reliable_command("vagrant ssh #{node_name} -c '/usr/bin/sudo /bin/systemctl start #{ntp_service}.service'")
      Dir.chdir pwd
    when DOCKER
      change_current_docker_snapshot(node_name, full_snapshot_name)
      current_dir = Dir.pwd
      Dir.chdir @path_to_nodes
      run_reliable_command("vagrant destroy -f #{node_name}")
      run_reliable_command("vagrant up #{node_name} --no-provision --provider #{DOCKER}")
      Dir.chdir current_dir
    else
      current_dir = Dir.pwd
      Dir.chdir @path_to_nodes
      run_reliable_command("vagrant snap rollback #{node_name} --name=#{full_snapshot_name}")
      Dir.chdir current_dir
    end
  end

  def revert_snapshots(snapshot_name)
    get_nodes.each do |node_name|
      revert_snapshot(node_name, snapshot_name)
    end
  end

  def remove_snapshot(node_name, snapshot_name)
    full_snapshot_name = "#{SNAPSHOT_GLOBAL_PREFIX}_#{snapshot_name}_#{@nodes_directory_name}_#{node_name}"
    @ui.info "Removing snapshot #{full_snapshot_name} for node #{node_name}"
    raise SNAPSHOTS_NOT_FOUND if get_snapshots(node_name).empty?
    raise SNAPSHOT_NOT_EXISTS unless get_snapshots(node_name).include? full_snapshot_name
    case @provider
    when LIBVIRT
      run_reliable_command("virsh snapshot-delete --domain #{@nodes_directory_name}_#{node_name} --snapshotname #{full_snapshot_name}")
    when DOCKER
      if (get_docker_initial_snapshot(node_name) == full_snapshot_name) || (get_docker_current_snapshot(node_name) == full_snapshot_name)
        raise "#{full_snapshot_name} #{DOCKER_SNAPSHOT_INITIAL_OR_IN_USE_NO_DELETION}"
      end
      raise "#{node_name} #{DOCKER_MACHINE_NOT_CREATED}" unless get_docker_containers_ids.include? node_name
      raise "#{full_snapshot_name} #{DOCKER_SNAPSHOT_EXISTS}" unless get_docker_snapshots(node_name).include? full_snapshot_name
      run_reliable_command("docker rmi #{full_snapshot_name}")
      remove_docker_snapshot_information(node_name, full_snapshot_name)
    else
      current_dir = Dir.pwd
      Dir.chdir @path_to_nodes
      run_reliable_command("vagrant snap delete #{node_name} --name=#{full_snapshot_name}")
      Dir.chdir current_dir
    end
  end
end

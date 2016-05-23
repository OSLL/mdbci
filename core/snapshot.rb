require_relative 'session'
require_relative 'out'


class Snapshot

  SNAPSHOT_ACTION_REQUIRED = 'snapshot action is required (take, revert, delete)'

  PATH_TO_NODES_OPTION_REQUIRED = '--path-to-nodes option must be specified'
  SNAPSHOT_NAME_AND_NODE_NAME_OPTIONS_REQUIRED = '--node-name and --snapshot-name must be specified both or not at all'

  NON_ZERO_BASH_EXIT_CODE_ERROR = 'command exited with non zero exit code'

  DOCKER_SNAPSHOT_NOT_FOUND = 'docker snapshot is not found'
  DOCKER_MACHINE_NOT_CREATED = 'docker machine is not created'
  DOCKER_SNAPSHOT_EXISTS = 'docker snapshot already exists'
  DOCKER_CONTAINER_ID_NOT_FOUND = 'docker container id not found'
  DOCKER_SNAPSHOT_INITIAL_OR_IN_USE_NO_DELETION = 'docker snapshot is initial or in use and could not be deleted'
  DOCKER_SNAPSHOT_NAME_MUST_BE_DOWNCASE = 'docker snapshot must be downcase'
  DOCKER_IMAGE_NAME_EXISTS = 'docker snapshot name is an image name, and that name already exists (check with "docker images")'

  NODES_NOT_FOUND_ERROR = 'nodes are not found'
  SNAPSHOT_ALREADY_EXISTS = 'snapshot already exists'
  SNAPSHOT_NOT_EXISTS = 'snapshot does not exist'

  HELP_OPTION = '--help'
  NODE_NAME_OPTION = '--node-name'
  PATH_TO_NODES_OPTION = '--path-to-nodes'
  SNAPSHOT_NAME_OPTION = '--snapshot-name'

  LIBVIRT = 'libvirt'
  DOCKER = 'docker'
  VIRTUALBOX = 'virtualbox'

  TEMPLATE_COOKBOOK_PATH = 'cookbook_path'
  TEMPLATE_AWS_CONFIG = 'aws_config'

  ACTION_TAKE = 'take'
  ACTION_REVERT = 'revert'
  ACTION_LIST = 'list'
  ACTION_REMOVE = 'remove'

  attr_accessor :provider
  attr_accessor :path_to_nodes
  # @nodes is an array of nodes names
  attr_accessor :nodes
  attr_accessor :nodes_directory_name
  # @docker_container_ids is a hash -> { NODE_NAME => CONTAINER_ID }
  attr_accessor :node_name
  attr_accessor :snapshot_name

  def initialize
    @path_to_nodes = $session.path_to_nodes
    @node_name = $session.node_name
    @snapshot_name = $session.snapshot_name
    raise PATH_TO_NODES_OPTION_REQUIRED if @path_to_nodes.to_s.empty?
    @nodes_directory_name = @path_to_nodes.to_s.split('/')[-1]
    @provider = File.read("#{@path_to_nodes}/provider")
    @nodes = get_nodes
  end

  def do(action)
    raise SNAPSHOT_ACTION_REQUIRED if action.to_s.empty?
    case action
      when ACTION_TAKE
        if !@node_name.to_s.empty? and !@snapshot_name.to_s.empty?
          $out.info "Taking snapshot of #{@node_name} to #{@snapshot_name}"
          take_snapshot(@node_name, @snapshot_name)
        elsif @node_name.to_s.empty? and @snapshot_name.to_s.empty?
          $out.info "Taking snapshot of all nodes in #{@path_to_nodes}"
          take_snapshots
        else
          raise SNAPSHOT_NAME_AND_NODE_NAME_OPTIONS_REQUIRED
        end
      when ACTION_REVERT
        if !@node_name.to_s.empty? and !@snapshot_name.to_s.empty?
          $out.info "Reverting node #{@node_name} to snapshot #{@snapshot_name}"
          revert_snapshot(@node_name, @snapshot_name)
        elsif @node_name.to_s.empty? and @snapshot_name.to_s.empty?
          $out.info "Reverting all nodes in #{@path_to_nodes} to snapshot last snapshot"
          revert_snapshots
        else
          raise SNAPSHOT_NAME_AND_NODE_NAME_OPTIONS_REQUIRED
        end
      when ACTION_REMOVE
        if !@node_name.to_s.empty? and !@snapshot_name.to_s.empty?
          $out.info "Removing snapshot #{@snapshot_name} for node #{@node_name}"
          remove_snapshot(@node_name, @snapshot_name)
        elsif @node_name.to_s.empty? and @snapshot_name.to_s.empty?
          $out.info "Removing all snapshots for node #{@node_name}"
          remove_snapshots
        else
          raise SNAPSHOT_NAME_AND_NODE_NAME_OPTIONS_REQUIRED
        end
      when ACTION_LIST
        if !@node_name.to_s.empty?
          list_snapshot node_name
        else
          list_snapshots
        end
    end
    return 0
  end

  def get_nodes
    nodes = Array.new
    template = JSON.parse(File.read(File.read("#{@path_to_nodes}/template")))
    template.each do |possible_node|
      if possible_node[0] != TEMPLATE_AWS_CONFIG and possible_node[0] != TEMPLATE_COOKBOOK_PATH
        nodes.push possible_node[0]
      end
    end
    raise NODES_NOT_FOUND_ERROR if nodes.empty?
    return nodes
  end

  # Return hash like -> { node0 => id0, node1 => id1, ... }
  def get_docker_containers_ids
    container_ids = Hash.new
    @nodes.each do |node_name|
      begin
        container_ids[node_name] = File.read("#{@path_to_nodes}/.vagrant/machines/#{node_name}/docker/id")
      rescue Errno::ENOENT => e
      end
    end
    return container_ids
  end

  def get_docker_node_id(node_name)
    snapshot_information = JSON.parse(File.read("#{@path_to_nodes}/#{node_name}/snapshots"))
    return snapshot_information[node_name]['id']
  end

  # Returns array of snapshots names
  def get_docker_snapshots(node_name)
    snapshot_information = JSON.parse(File.read("#{@path_to_nodes}/#{node_name}/snapshots"))
    return snapshot_information[node_name]['snapshots']
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
    return snapshots[node_name]['initial_snapshot']
  end

  def get_docker_current_snapshot(node_name)
    snapshots = JSON.parse(File.read("#{@path_to_nodes}/#{node_name}/snapshots"))
    return snapshots[node_name]['current_snapshot']
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
  def execute_bash(cmd, disable_stdout_output, return_output)
    output = String.new
    process_status = Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thr|
      stdin.close
      stdout.each do |line|
        $out.info line unless disable_stdout_output
        output = output + line if return_output
      end
      stdout.close
      stderr.each { |line| $out.error line }
      stderr.close
      wait_thr.value.exitstatus
    end
    raise "#{cmd} #{NON_ZERO_BASH_EXIT_CODE_ERROR} #{process_status}" unless process_status == 0
    unless return_output
      return process_status
    end
    return process_status, output
  end

  def get_docker_images
    _, output = execute_bash('docker images --format "{{.Repository}}"', true, true)
    return output.split("\n")
  end

  # args[0] node name
  # no arguments => all nodes
  def get_snapshots(node_name)
    case @provider
      when LIBVIRT
        _, output = execute_bash("virsh -q snapshot-list --domain #{@nodes_directory_name}_#{node_name} | awk '{print $1}'", true, true)
        return output.split("\n")
      when DOCKER
        return get_docker_snapshots(node_name)
      else
        current_dir = Dir.pwd
        Dir.chdir @path_to_nodes
        _, output = execute_bash("vagrant snap list #{node_name} | grep +.* | awk '{print $2}'", true, true)
        Dir.chdir current_dir
        return output.split("\n")
    end
  end

  # args[0] node name
  # no arguments => all nodes
  def list_snapshot(node_name)
    puts get_snapshots node_name
  end

  def list_snapshots
    @nodes.each do |node_name|
      list_snapshot node_name
    end
  end

  def take_snapshot(node_name, snapshot_name)
    raise SNAPSHOT_ALREADY_EXISTS if get_snapshots(node_name).include? snapshot_name
    case @provider
      when LIBVIRT
        execute_bash("virsh snapshot-create-as --domain #{@nodes_directory_name}_#{node_name} --name #{snapshot_name}", false, false)
      when DOCKER
        raise DOCKER_IMAGE_NAME_EXISTS if get_docker_images.include? snapshot_name
        raise DOCKER_SNAPSHOT_NAME_MUST_BE_DOWNCASE unless snapshot_name == snapshot_name.to_s.downcase
        docker_containers_ids = get_docker_containers_ids
        raise "#{node_name} #{DOCKER_MACHINE_NOT_CREATED}" unless docker_containers_ids.include? node_name
        execute_bash("docker commit -p #{docker_containers_ids[node_name]} #{snapshot_name}", false, false)
        add_docker_snapshot_information(node_name, snapshot_name)
      else
        current_dir = Dir.pwd
        Dir.chdir @path_to_nodes
        execute_bash("vagrant snap take #{node_name} --name=#{snapshot_name}", false, false)
        Dir.chdir current_dir
    end
  end

  def take_snapshots
    @nodes.each do |node_name|
      take_snapshot(node_name, "#{@nodes_directory_name}_#{node_name}_#{Time.now.to_i}")
    end
  end

  def revert_snapshot(node_name, snapshot_name)
    case @provider
      when LIBVIRT
        execute_bash("virsh snapshot-revert --domain #{@nodes_directory_name}_#{node_name} --snapshotname #{snapshot_name}", false, false)
      when DOCKER
        change_current_docker_snapshot(node_name, snapshot_name)
        current_dir = Dir.pwd
        Dir.chdir @path_to_nodes
        execute_bash("vagrant destroy -f #{node_name}", false, false)
        execute_bash("vagrant up #{node_name} --no-provision --provider #{DOCKER}", false, false)
        Dir.chdir current_dir
      else
        execute_bash("vagrant snap rollback #{node_name} --name=#{snapshot_name}", false, false)
    end
  end

  def revert_snapshots
    case @provider
      when LIBVIRT
        @nodes.each do |node_name|
          execute_bash("virsh snapshot-revert --domain #{@nodes_directory_name}_#{node_name} --current", false, false)
        end
      when DOCKER
        @nodes.each do |node_name|
          revert_snapshot(node_name, get_docker_current_snapshot(node_name))
        end
      else
        current_dir = Dir.pwd
        Dir.chdir @path_to_nodes
        @nodes.each do |node_name|
          execute_bash("vagrant snap rollback #{node_name}", false, false)
        end
        Dir.chdir current_dir
    end
  end

  def remove_snapshot(node_name, snapshot_name)
    raise SNAPSHOT_NOT_EXISTS unless get_snapshots(node_name).include? snapshot_name
    case @provider
      when LIBVIRT
        execute_bash("virsh snapshot-delete --domain #{@nodes_directory_name}_#{node_name} --snapshotname #{snapshot_name}", false, false)
      when DOCKER
        if get_docker_initial_snapshot(node_name) == snapshot_name or get_docker_current_snapshot(node_name) == snapshot_name
          raise "#{snapshot_name} #{DOCKER_SNAPSHOT_INITIAL_OR_IN_USE_NO_DELETION}"
        end
        raise "#{node_name} #{DOCKER_MACHINE_NOT_CREATED}" unless get_docker_containers_ids.include? node_name
        raise "#{snapshot_name} #{DOCKER_SNAPSHOT_EXISTS}" unless get_docker_snapshots(node_name).include? snapshot_name
        execute_bash("docker rmi #{snapshot_name}", false, false)
        remove_docker_snapshot_information(node_name, snapshot_name)
      else
        execute_bash("vagrant snap delete #{node_name} --name=#{snapshot_name}", false, false)
    end
  end

  def remove_snapshots
    @nodes.each do |node_name|
      get_snapshots(node_name).each do |snapshot_name|
        remove_snapshot(node_name, snapshot_name)
      end
    end
  end
end

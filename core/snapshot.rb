require_relative 'out'

class Snapshot

  NON_ZERO_BASH_EXIT_CODE_ERROR = 'command exited with non zero exit code:'
  SNAPSHOT_NAME_REQUIRED = 'snapshot name is required'
  NODE_NAME_REQUIRED = 'node name is required'
  DOCKER_SNAPSHOT_NOT_FOUND = 'docker snapshot is not found'

  LIBVIRT = 'libvirt'
  DOCKER = 'docker'

  attr_accessor :provider
  attr_accessor :path_to_nodes
  # @nodes is an array of nodes names
  attr_accessor :nodes
  attr_accessor :nodes_directory_name
  # @docker_container_ids is a hash -> {NODE_NAME=>CONTAINER_ID}
  attr_accessor :docker_containers_ids

  def initialize(path_to_nodes)
    @path_to_nodes = path_to_nodes
    @nodes_directory_name = path_to_nodes.to_s.split('/')[-1]
    @provider = File.read "#{@path_to_nodes}/provider"
    @nodes = get_nodes
    if @provider == DOCKER
      @docker_containers_ids = get_docker_containers_ids
    else
      @docker_containers_ids = nil
    end
  end

  def get_nodes
    nodes = Array.new
    Dir.glob(path + "#{@path_to_nodes}/*.json").each do |f|
      @nodes.push f.chomp '.json'
    end
    return nodes
  end

  def get_docker_containers_ids
    container_ids = Hash.new
    @nodes.each do |node_name|
      container_ids[node_name] = File.read("#{@path_to_nodes}/.vagrant/machines/#{node_name}/docker/id")
    end
    return container_ids
  end

  def save_docker_snapshot_information(node_name, snapshot_name)
    snapshot_information = JSON.parse(File.read("#{@path_to_nodes}/#{node_name}/snapshots"))
    snapshot_information[node_name]['snapshots'] << snapshot_name
    File.open("#{@path_to_nodes}/#{node_name}/snapshots", 'w') do |f|
      f.puts snapshot_information.to_json
    end
  end

  def get_docker_snapshots(node_name)
    snapshots = JSON.parse(File.read("#{@path_to_nodes}/#{node_name}/snapshots"))
    return snapshots[node_name]['snapshots']
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
  def execute_bash(cmd)
    stderr_from_bash = ''
    process_status = Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thr|
      stdin.close
      stdout.each { |line| $out.info line }
      stderr_from_bash = stderr.read
      wait_thr.value.exitstatus
    end
    raise stderr_from_bash unless stderr_from_bash.to_s.empty?
    raise "#{cmd} #{NON_ZERO_BASH_EXIT_CODE_ERROR} #{process_status}" unless stderr_from_bash.to_s.empty?
    return process_status
  end

  # args[0] node name
  # no arguments => all nodes
  def list(node_name)
    case @provider
      when LIBVIRT
        execute_bash("virsh -q snapshot-list --domain #{node_name} | awk '{print $1}'")
      when DOCKER
        puts get_docker_snapshots(node_name)
      else
        execute_bash("vagrant snap list #{node_name}")
    end
  end

  def take_snapshot(node_name, snapshot_name)
    raise NODE_NAME_REQUIRED if node_name.nil?
    raise SNAPSHOT_NAME_REQUIRED if snapshot_name.nil?
    case @provider
      when LIBVIRT
        execute_bash("virsh snapshot-create-as --domain #{@nodes_directory_name}_#{node_name} --name #{snapshot_name}")
      when DOCKER
        execute_bash("docker commit -p #{@docker_container_ids[node_name]} #{snapshot_name}")
        save_docker_snapshot_information(node_name, snapshot_name)
      else
        execute_bash("vagrant snap take #{node_name} --name=#{snapshot_name}")
    end
  end

  def take_snapshots
    timestamp = Time.now.to_i
    @nodes.each do |node_name|
      take_snapshot(node_name, "#{@nodes_directory_name}_#{node_name}_#{timestamp}")
    end
  end

  # args[0] node name, args[1] snapshot name
  # no arguments => all nodes
  def take(*args)
    if args.size > 1 and !args[1].nil?
      take_snapshot(args[0], args[1])
    else
      take_snapshots
    end
  end

  def revert_snapshot(node_name, snapshot_name)
    raise NODE_NAME_REQUIRED if node_name.nil?
    raise SNAPSHOT_NAME_REQUIRED if snapshot_name.nil?
    case @provider
      when LIBVIRT
        execute_bash("virsh snapshot-revert --domain #{@nodes_directory_name}_#{node_name} --snapshotname #{snapshot_name}")
      when DOCKER
        current_dir = Dir.pwd
        Dir.chdir @path_to_nodes
        execute_bash("vagrant destroy -f #{node_name}")
        change_current_docker_snapshot(node_name, snapshot_name)
        execute_bash("vagrant up #{node_name} --no-provision")
        Dir.chdir current_dir
        # update ids for docker containers
        @docker_containers_ids = get_docker_containers_ids
      else
        execute_bash("vagrant snap rollback #{node_name} --name=#{snapshot_name}")
    end
  end

  def revert_snapshots
    case @provider
      when LIBVIRT
        @nodes.each do |node_name|
          execute_bash("virsh snapshot-revert --domain #{@nodes_directory_name}_#{node_name} --current")
        end
      when DOCKER
        @nodes.each do |node_name|
          revert_snapshot(node_name, get_docker_snapshots(node_name)[-1])
        end
      else
        @nodes.each do |node_name|
          execute_bash("vagrant snap rollback #{node_name}")
        end
  end

  # args[0] node name, args[1] snapshot name
  # no arguments => all nodes
  def revert(*args)
    if args.size > 1
      revert_snapshot(args[0], args[1])
    else
      revert_snapshots
    end
  end

end

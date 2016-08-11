require_relative 'boxes_manager'

TEMPLATE_COOKBOOK_PATH = 'cookbook_path'
TEMPLATE_AWS_CONFIG = 'aws_config'

MACHINE_NOT_CREATED_ERROR = 'machine is not created'
NODES_NOT_FOUND_ERROR = 'machines not found'
TEMPLATE_NOT_FOUND_ERROR = 'template not found'
NON_ZERO_BASH_EXIT_CODE_ERROR = 'command exited with non zero exit code'
MDBCI_MACHINE_HAS_NO_ID_ERROR = 'mdbci machine does not have id'
ACTION_NOT_SUPPORTED_FOR_PPC = 'action is not supported for machines with \'mdbci(ppc)\' provider'
UNKNOWN_PROVIDER_ERROR = 'provider is unknown (file with provider definition is missing)'
TEMPLATE_FILE_NOT_FOUND = 'template (or mdbci_template) file not found'
TEMPLATE_PATH_EMPTY = 'template (or mdbci_template) path is empty'

MDBCI = 'mdbci'
DOCKER = 'docker'

RUNNING = 'running'
SHUTOFF = 'shutoff' # when call 'vagrant halt'
SHUTTING_DOWN = 'shutting down' # sometimes libvirt gets in this state before shutoff state
STOPPED = 'stopped' # when call 'vagrant halt' on docker machine
NOT_CREATED = 'not created' # when machine has never been started
PAUSED = 'paused' # when machine is suspended

BOX = 'box'

def out_info(content)
  puts " INFO: #{content}"
end

def out_error(content)
  puts "ERROR: #{content}"
end

def get_provider(path_to_nodes)
  begin
    return File.read "./#{path_to_nodes}/provider"
  rescue Exception => e
    raise "#{path_to_nodes}: #{UNKNOWN_PROVIDER_ERROR}, #{e.message}"
  end
end

def get_template_path(path_to_nodes)
  provider = get_provider(path_to_nodes)
  template_path = nil
  begin
    if provider == MDBCI
      template_path = File.read "#{path_to_nodes}/mdbci_template" 
    else
      template_path = File.read "#{path_to_nodes}/template"
    end
  rescue Exception => e
    raise "#{path_to_nodes}: #{TEMPLATE_FILE_NOT_FOUND} (#{e.message})"
  end
  raise "#{path_to_nodes}: #{TEMPLATE_PATH_EMPTY}" if template_path.empty?
  return template_path
end

def get_template_directory(path_to_nodes)
  template_path = get_template_path path_to_nodes
  paths = template_path.split('/')
  path = paths[0..-2].join('/')
  return Dir.pwd if path.empty?
  return path
end

def get_nodes(path_to_nodes)
  nodes = Array.new
  template = JSON.parse(File.read(get_template_path(path_to_nodes)))
  template.each do |possible_node|
    if possible_node[0] != TEMPLATE_AWS_CONFIG and possible_node[0] != TEMPLATE_COOKBOOK_PATH
      nodes.push possible_node[0]
    end
  end
  raise "#{path_to_nodes}: #{NODES_NOT_FOUND_ERROR}" if nodes.empty?
  return nodes
end

# method gets id of machine node
def get_node_machine_id(path_to_nodes, node_name)
  provider = get_provider path_to_nodes
  if provider == MDBCI
    raise "getting id for #{path_to_nodes}/#{node_name}: #{ACTION_NOT_SUPPORTED_FOR_PPC}"
  end
  begin
    return File.read("#{path_to_nodes}/.vagrant/machines/#{node_name}/#{provider}/id")
  rescue
    raise $!, "#{path_to_nodes}/#{node_name}: #{MACHINE_NOT_CREATED_ERROR}", $!.backtrace
  end
end

# method sets id for machine node
def set_node_machine_id(path_to_nodes, node_name, id)
  provider = get_provider path_to_nodes
  if provider == MDBCI
    raise "setting id for #{path_to_nodes}/#{node_name}: #{ACTION_NOT_SUPPORTED_FOR_PPC}"
  end
  path_to_id = "#{path_to_nodes}/.vagrant/machines/#{node_name}/#{provider}/id"
  unless File.exist? path_to_id
    raise "#{path_to_nodes}/#{node_name}: #{MACHINE_NOT_CREATED_ERROR}"
  end
  File.open(path_to_id, 'w') { |file| file.write id }
end


class Timeout

  attr_accessor :time
  attr_accessor :start_time
  attr_accessor :counter
  attr_accessor :thread
  attr_accessor :terminated

  def start(time)
    @time = time
    @start_time = Time.now.to_i
    @terminated = false
    unless time == 0
      puts 'timer started'
      @thread = Thread.new do
        while true
          break if @terminated
          puts (Time.now.to_i - @start_time)
          if (Time.now.to_i - @start_time) >= @time
            puts 'timer is raising exception'
            raise "timer expired" 
          end
          sleep 1
        end
      end
      @thread.abort_on_exception = true
    end
    yield
  end

  def reset
    unless @time==0
      puts 'timer reset'
      @start_time = Time.now.to_i
    end
  end

  def destroy
    unless @time == 0
      puts 'timer destroyed'
      @terminated = true 
    end
  end

  class TimeoutExpiration < RuntimeError
  end

end

# method returns bash command exit code
def execute_bash(cmd, silent = false, execution_timeout = 0)
  output = String.new
  process_status = nil
  begin
    process_status = Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thr|
      stdin.close
      timeout_stdout = Timeout.new
      timeout_stderr = Timeout.new
      timeout_stdout.start(execution_timeout) do
        stdout.each do |line|
          out_info line unless silent
          output = output + line
          timeout_stdout.reset
        end
      end
      timeout_stdout.destroy
      timeout_stderr.start(execution_timeout) do
        stderr.each do |line| 
          out_error line
          timeout_stderr.reset
        end
      end
      timeout_stderr.destroy
=begin
      begin
      rescue Timeout::TimeoutExpiration => e
        puts 'aaa'
        puts File.read("/proc/#{w.pid}/fd/1")
        timeout.destroy
        #Process.kill('TERM', w.pid)
        #Process.wait
        #stdout.each { |line| out_info line }
        #stderr.each { |line| out_info line }
        raise
      ensure
        #stdout.close unless stdout.nil?
        #stderr.close unless stderr.nil?
        timeout.destroy
      end
=end
      wait_thr.value.exitstatus
    end
  rescue Exception => e
    raise $!, e.message, $!.backtrace
  end
  raise "#{cmd}: #{NON_ZERO_BASH_EXIT_CODE_ERROR} - #{process_status}" unless process_status == 0
  return output
end

def destroy_config(config_name)
  if Dir.exist? config_name
    unless get_provider(config_name) == MDBCI
      root_dir = Dir.pwd
      Dir.chdir config_name
      execute_bash('vagrant destroy -f')
      Dir.chdir root_dir
    end
    FileUtils.rm_rf config_name
  end
end

def stop_config_node(config_name, node_name)
  if get_provider(config_name) == MDBCI
    raise "stopping machine #{config_name}/#{node_name}: #{ACTION_NOT_SUPPORTED_FOR_PPC}"
  end
  root_directory = Dir.pwd
  Dir.chdir config_name
  execute_bash("vagrant halt #{node_name}")
  Dir.chdir root_directory
  begin
    out_info 'waiting machine to be shutted down (2 seconds)'
    sleep 2
  end while get_config_node_status(config_name, node_name) == SHUTTING_DOWN
end

def suspend_config_node(config_name, node_name)
  if get_provider(config_name) == MDBCI
    raise "stopping machine #{config_name}/#{node_name}: #{ACTION_NOT_SUPPORTED_FOR_PPC}"
  end
  root_directory = Dir.pwd
  Dir.chdir config_name
  execute_bash("vagrant suspend #{node_name}")
  Dir.chdir root_directory
end

def resume_config_node(config_name, node_name)
  if get_provider(config_name) == MDBCI
    raise "stopping machine #{config_name}/#{node_name}: #{ACTION_NOT_SUPPORTED_FOR_PPC}"
  end
  root_directory = Dir.pwd
  Dir.chdir config_name
  execute_bash("vagrant resume #{node_name}")
  Dir.chdir root_directory
end

def stop_config(config_name)
  if get_provider(config_name) == MDBCI
    raise "stopping config #{config_name}: #{ACTION_NOT_SUPPORTED_FOR_PPC}"
  end
  nodes = get_nodes(config_name)
  nodes.each { |node_name| stop_config_node(config_name, node_name) }
  root_directory = Dir.pwd
  Dir.chdir config_name
  execute_bash('vagrant halt')
  Dir.chdir root_directory
end

def start_config_node(config_name, node_name, no_provision = true)
  provider = get_provider(config_name)
  if provider == MDBCI
    raise "starting machine #{config_name}/#{node_name}: #{ACTION_NOT_SUPPORTED_FOR_PPC}"
  end
  root_directory = Dir.pwd
  Dir.chdir config_name
  no_provision_cmd = no_provision ? '--no-provision' : ''
  execute_bash("vagrant up --provider #{provider} #{no_provision_cmd}")
  Dir.chdir root_directory
end

def start_config(config_name, no_provision = false, no_parallel = false)
  provider = get_provider(config_name)
  if provider == MDBCI
    raise "starting config #{config_name}: #{ACTION_NOT_SUPPORTED_FOR_PPC}"
  end
  root_directory = Dir.pwd
  Dir.chdir config_name
  no_provision_cmd = no_provision ? '--no-provision' : ''
  no_parallel_cmd = no_parallel ? '--no-parallel' : ''
  execute_bash("vagrant up --provider #{provider} #{no_provision_cmd} #{no_parallel_cmd}")
  Dir.chdir root_directory
end

def get_config_node_status(config_name, node_name)
  if get_provider(config_name) == MDBCI
    raise "getting status for #{config_name}/#{node_name}: #{ACTION_NOT_SUPPORTED_FOR_PPC}"
  end
  root_dir = Dir.pwd
  Dir.chdir config_name
  output = execute_bash("vagrant status #{node_name}", true)
  output = output.to_s.split("\n")[2].split(/\s+/)
  Dir.chdir root_dir
  if output.size == 4
    return "#{output[1]} #{output[2]}"
  elsif  output.size == 3
    return "#{output[1]}"
  end
end

# true - node is running, otherwise false
def is_config_node_running(config_name, node_name)
  if get_config_node_status(config_name, node_name) == RUNNING
    return true
  end
  return false
end

# true - node is running, otherwise false
def is_config_node_paused(config_name, node_name)
  if get_config_node_status(config_name, node_name) == PAUSED
    return true
  end
  return false
end

# true - node is running, otherwise false
def is_config_node_ever_started(config_name, node_name)
  unless get_config_node_status(config_name, node_name) == NOT_CREATED
    return true
  end
  return false
end

# true - node is was shutted down, otherwise false
def is_config_node_stopped(config_name, node_name)
  status = get_config_node_status(config_name, node_name)
  if status == STOPPED or status == SHUTOFF
    return true
  end
  return false
end

# true - all node are running, otherwise false
def is_config_running(config_name)
  nodes = get_nodes config_name
  nodes.each do |node_name|
    return false unless is_config_node_running(config_name, node_name)
  end
  return true
end

# true - all node are running, otherwise false
def is_config_paused(config_name)
  nodes = get_nodes config_name
  nodes.each do |node_name|
    return false unless is_config_node_paused(config_name, node_name)
  end
  return true
end

# true - all node are running, otherwise false
def is_config_ever_started(config_name)
  nodes = get_nodes config_name
  nodes.each do |node_name|
    return false unless is_config_node_ever_started(config_name, node_name)
  end
  return true
end

# true - all node are running, otherwise false
def is_config_stopped(config_name)
  nodes = get_nodes config_name
  return false unless nodes
  nodes.each do |node_name|
    return false unless is_config_node_stopped(config_name, node_name)
  end
  return true
end

# true - all nodes are fully created, otherwise false
def is_config_created(config_name)
  return false unless Dir.exist? config_name
  provider = get_provider(config_name) rescue nil
  return false unless provider
  if provider != MDBCI
    return false unless File.exist? "#{config_name}/Vagrantfile"
    return false unless File.exist? "#{config_name}/template"
    nodes_names = get_nodes(config_name) rescue nil
    return false unless nodes_names
    if provider == DOCKER
      return false unless nodes_names
      nodes_names.each do |node_name|
        return false unless Dir.exist? "#{config_name}/#{node_name}"
        return false unless File.exist? "#{config_name}/#{node_name}/Dockerfile"
        return false unless File.exist? "#{config_name}/#{node_name}/snapshots"
      end
    end
  else
    return false unless File.exist? "#{config_name}/mdbci_template"
  end
  return true
end

def get_box_name_from_node(path_to_nodes, node_name)
  template = JSON.parse(File.read (get_template_path path_to_nodes))
  return template[node_name][BOX]
end
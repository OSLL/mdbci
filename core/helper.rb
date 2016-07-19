require_relative 'boxes_manager'

TEMPLATE_COOKBOOK_PATH = 'cookbook_path'
TEMPLATE_AWS_CONFIG = 'aws_config'

MACHINE_NOT_CREATED_ERROR = 'machine is not created'
NODES_NOT_FOUND_ERROR = 'machines not found'
TEMPLATE_NOT_FOUND_ERROR = 'template not found'
NON_ZERO_BASH_EXIT_CODE_ERROR = 'command exited with non zero exit code'
MDBCI_MACHINE_HAS_NO_ID_ERROR = 'mdbci machine does not have id'
MDBCI_NOT_SUPPORT = 'mdbci provider does not support this action'
UNKNOWN_PROVIDER_ERROR = 'provider is unknown (file with provider definition is missing)'
TEMPLATE_FILE_NOT_FOUND = 'template (or mdbci_template) file not found'
TEMPLATE_PATH_EMPTY = 'template (or mdbci_template) path is empty'

MDBCI = 'mdbci'
DOCKER = 'docker'

def out_info(content)
  puts "  INFO: #{content}"
end

def out_error(content)
  puts "ERROR: #{content}"
end

def get_provider(path_to_nodes)
  begin
    return File.read "#{path_to_nodes}/provider"
  rescue
    raise "#{path_to_nodes} #{UNKNOWN_PROVIDER_ERROR}"
  end
end

def get_nodes(path_to_nodes)
  nodes = Array.new
  template = nil
  begin
    template = JSON.parse(File.read(File.read("#{path_to_nodes}/template")))
  rescue
    begin
      template = JSON.parse(File.read(File.read("#{path_to_nodes}/mdbci_template")))
    rescue
      raise $!, "#{path_to_nodes}/template or #{path_to_nodes}/mdbci_template #{TEMPLATE_NOT_FOUND_ERROR}", $1.backtrace
    end
  end
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
  if provider == 'mdbci'
    raise "#{path_to_nodes}/#{node_name}: #{MDBCI_MACHINE_HAS_NO_ID_ERROR}"
  end
  begin
    return File.read("#{path_to_nodes}/.vagrant/machines/#{node_name}/#{provider}/id")
  rescue Exception => e
    raise $!, "#{path_to_nodes}/#{node_name}: #{MACHINE_NOT_CREATED_ERROR}", $!.backtrace
  end
end

# method sets id for machine node
def set_node_machine_id(path_to_nodes, node_name, id)
  provider = get_provider path_to_nodes
  if provider == 'mdbci'
    raise "#{path_to_nodes}/#{node_name}: #{MDBCI_MACHINE_HAS_NO_ID_ERROR}"
  end
  path_to_id = "#{path_to_nodes}/.vagrant/machines/#{node_name}/#{provider}/id"
  unless File.exist? path_to_id
    raise "#{path_to_nodes}/#{node_name}: #{MACHINE_NOT_CREATED_ERROR}"
  end
  File.open(path_to_id, 'w') { |file| file.write id }
end

# method returns bash command exit code
def execute_bash(cmd, silent = false)
  output = String.new
  process_status = nil
  begin
    process_status = Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thr|
      stdin.close
      stdout.each do |line|
        out_info line unless silent
        output = output + line
      end
      stdout.close
      stderr.each { |line| out_error line }
      stderr.close
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
  raise "#{MDBCI_NOT_SUPPORT}" if get_provider(config_name)== MDBCI
  root_directory = Dir.pwd
  Dir.chdir config_name
  execute_bash("vagrant halt #{node_name}")
  Dir.chdir root_directory
end

def stop_config(config_name)
  raise "#{MDBCI_NOT_SUPPORT}" if get_provider(config_name) == MDBCI
  root_directory = Dir.pwd
  Dir.chdir config_name
  execute_bash('vagrant halt')
  Dir.chdir root_directory
end

def start_config_node(config_name, node_name, provider)
  raise "#{MDBCI_NOT_SUPPORT}" if provider == MDBCI
  root_directory = Dir.pwd
  Dir.chdir config_name
  execute_bash("vagrant up #{node_name} --provider #{provider}")
  Dir.chdir root_directory
end

def start_config(config_name, provider)
  raise "#{MDBCI_NOT_SUPPORT}" if provider == MDBCI
  root_directory = Dir.pwd
  Dir.chdir config_name
  execute_bash("vagrant up --provider #{provider}")
  Dir.chdir root_directory
end

# true - node is running, otherwise false
def is_config_node_running(config_name, node_name)
  root_dir = Dir.pwd
  Dir.chdir config_name
  output = execute_bash("vagrant status #{node_name}", true) rescue nil
  return false unless output
  output = output.to_s.split("\n")[2].split(/\s+/)
  Dir.chdir root_dir
  if output.to_a.size == 4 or output.to_a.size == 3 and output[1] != 'running'
    return false
  end
  return true
end

# true - all node are running, otherwise false
def is_config_running(config_name)
  nodes = get_nodes config_name rescue nil
  return false unless nodes
  nodes.each do |node_name|
    return false unless is_config_node_running(config_name, node_name)
  end
  return true
end

# true - all node are fully created, otherwise false
def is_config_created(config_name)
  return false unless Dir.exist? config_name
  provider = get_provider(config_name) rescue nil
  return false unless provider
  if provider != MDBCI
    return false unless File.exist? "#{config_name}/Vagrantfile"
    return false unless File.exist? "#{config_name}/template"
    nodes_names = get_nodes(config_name) rescue nil
    nodes_names.each do |node_name|
      return false unless File.exist? "#{config_name}/#{node_name}.json"
    end
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

def get_template_path(path_to_nodes)
  provider = get_provider(path_to_nodes)
  template_path = nil
  begin
    template_path = File.read "#{path_to_nodes}/mdbci_template" if provider == MDBCI
    template_path = File.read "#{path_to_nodes}/template"
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

def get_box_name_from_node(path_to_nodes, node_name)
  template = JSON.parse(File.read (get_template_path path_to_nodes))
  return template[node_name][BOX]
end


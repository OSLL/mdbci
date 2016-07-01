require 'open3'

require_relative 'out'

NON_ZERO_BASH_EXIT_CODE_ERROR = 'command exited with non zero exit code'
CONFIG_DIRECTORY_NOT_FOUND_ERROR = 'config directory is not found'
NODE_NOT_FOUND_ERROR = 'node is not found'
NODES_NOT_FOUND_ERROR = 'nodes are not found'
DOCKER_NODE_NOT_CREATED = 'docker node is not created (only generated)'

TEMPLATE_COOKBOOK_PATH = 'cookbook_path'
TEMPLATE_AWS_CONFIG = 'aws_config'

# method returns bash command output
def execute_bash(cmd, silent = false)
  output = String.new
  process_status = Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thr|
    stdin.close
    stdout.each do |line|
      $out.info line unless silent
      output = output + line
    end
    stdout.close
    stderr.each { |line| $out.error line }
    stderr.close
    wait_thr.value.exitstatus
  end
  raise "#{cmd} #{NON_ZERO_BASH_EXIT_CODE_ERROR} #{process_status}" unless process_status == 0
  return output
end

# method returns an array of nodes names (that are described in template)
def get_nodes(path_to_nodes)
  nodes = Array.new
  template = JSON.parse(File.read(File.read("#{path_to_nodes}/template")))
  template.each do |possible_node|
    if possible_node[0] != TEMPLATE_AWS_CONFIG and possible_node[0] != TEMPLATE_COOKBOOK_PATH
      nodes.push possible_node[0]
    end
  end
  raise NODES_NOT_FOUND_ERROR if nodes.empty?
  return nodes
end

# Return hash like -> { node0 => id0, node1 => id1, ... }
def get_docker_node_container_id(path_to_nodes, node_name)
  begin
  container_id = File.read("#{path_to_nodes}/.vagrant/machines/#{node_name}/docker/id")
  rescue
    raise "#{path_to_nodes}/#{node_name} #{DOCKER_NODE_NOT_CREATED}"
  end
  return container_id
end

# method returns new image name (which will be used later as a box for template)
def create_docker_node_clone(path_to_nodes, node_name, path_to_new_config_directory)
  raise "#{path_to_nodes} #{CONFIG_DIRECTORY_NOT_FOUND_ERROR}" unless Dir.exist? path_to_nodes
  raise "#{node_name} #{NODE_NOT_FOUND_ERROR}" unless get_nodes(path_to_nodes).include? node_name
  old_docker_image_name = get_docker_node_container_id(path_to_nodes, node_name)
  new_docker_image_name = "#{path_to_new_config_directory}_#{node_name}_#{Time.now.to_i}"
  execute_bash "docker commit -p #{old_docker_image_name} #{new_docker_image_name}"
  return new_docker_image_name
end
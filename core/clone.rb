require 'open3'

require_relative 'out'
require_relative 'helper'

CONFIG_DIRECTORY_NOT_FOUND_ERROR = 'config directory is not found'
NODE_NOT_FOUND_ERROR = 'node is not found'

# method returns new image name (which will be used later as a box for template)
def create_docker_node_clone(path_to_nodes, node_name, path_to_new_config_directory)
  raise "#{path_to_nodes} #{CONFIG_DIRECTORY_NOT_FOUND_ERROR}" unless Dir.exist? path_to_nodes
  raise "#{node_name} #{NODE_NOT_FOUND_ERROR}" unless get_nodes(path_to_nodes).include? node_name
  old_docker_image_name = get_node_machine_id(path_to_nodes, node_name)
  new_docker_image_name = "#{path_to_new_config_directory}_#{node_name}_#{Time.now.to_i}"
  execute_bash "docker commit -p #{old_docker_image_name} #{new_docker_image_name}"
  return new_docker_image_name
end
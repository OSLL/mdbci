require_relative 'out'
require_relative 'helper'

UUID_FOR_DOMAIN_NOT_FOUND_ERROR = 'uuid for domain is not found'
CONFIG_DIRECTORY_NOT_FOUND_ERROR = 'config directory is not found'
NODE_NOT_FOUND_ERROR = 'node is not found'
DOMAIN_NAME_FOR_UUID_NOT_FOUND_ERROR = 'uuid for domain is not found'
LIBVIRT_NODE_RUNNING_ERROR = 'libvirt node is not in shutoff state (for cloning state must be shutoff)'

def get_libvirt_uuid_by_domain_name(domain_name)
  list_output = execute_bash('virsh -q list --all | awk \'{print $2}\'', true).to_s.split "\n"
  list_uuid_output = execute_bash('virsh -q list --uuid --all', true).to_s.split "\n"
  list_output.zip(list_uuid_output).each do |domain, uuid|
    return uuid if domain == domain_name
  end
  raise "#{domain_name}: #{UUID_FOR_DOMAIN_NOT_FOUND_ERROR}"
end

# method returns new image name (which will be used later as a box for template)
def create_docker_node_clone(path_to_nodes, node_name, path_to_new_config_directory)
  raise "#{path_to_nodes} #{CONFIG_DIRECTORY_NOT_FOUND_ERROR}" unless Dir.exist? path_to_nodes
  raise "#{path_to_nodes}/#{node_name} #{NODE_NOT_FOUND_ERROR}" unless get_nodes(path_to_nodes).include? node_name
  old_docker_image_name = get_node_machine_id(path_to_nodes, node_name)
  new_docker_image_name = "#{path_to_new_config_directory}_#{node_name}_#{Time.now.to_i}"
  execute_bash "docker commit -p #{old_docker_image_name} #{new_docker_image_name}"
  return new_docker_image_name
end

# returns domain name by uuid
def get_libvirt_domain_name_by_uuid(uuid)
  list_output = execute_bash('virsh -q list --all | awk \'{print $2}\'', true).to_s.split "\n"
  list_uuid_output = execute_bash('virsh -q list --uuid --all', true).to_s.split "\n"
  list_output.zip(list_uuid_output).each do |domain, uuid_for_domain|
    return domain if uuid == uuid_for_domain
  end
  raise "#{uuid}: #{DOMAIN_NAME_FOR_UUID_NOT_FOUND_ERROR}"
end

# method returns new domain name (whose id will be used later as new id in copied config)
def create_libvirt_node_clone(path_to_nodes, node_name, path_to_new_config_directory)
  raise "#{path_to_nodes} #{CONFIG_DIRECTORY_NOT_FOUND_ERROR}" unless Dir.exist? path_to_nodes
  raise "#{path_to_nodes}/#{node_name} #{NODE_NOT_FOUND_ERROR}" unless get_nodes(path_to_nodes).include? node_name
  domain_uuid = get_node_machine_id(path_to_nodes, node_name)
  full_domain_name = get_libvirt_domain_name_by_uuid(domain_uuid)
  root_directory = Dir.pwd
  Dir.chdir path_to_nodes
  node_status = execute_bash("vagrant status #{node_name}", true).split("\n")[2]
  status = node_status.split(/\s+/)[1]
  puts status
  Dir.chdir root_directory
  raise "#{path_to_nodes}/#{node_name}: #{LIBVIRT_NODE_RUNNING_ERROR}" unless status.include? 'shutoff'
  new_docker_image_name = "#{path_to_new_config_directory}_#{node_name}_#{Time.now.to_i}"
  execute_bash "virt-clone -o #{full_domain_name} -n #{new_docker_image_name} --auto-clone"
  return new_docker_image_name
end

def replace_libvirt_node_id(path_to_nodes, node_name, id)
  set_node_machine_id(path_to_nodes, node_name, id)
end
require 'fileutils'

require_relative 'out'
require_relative 'helper'
require 'fileutils'

UUID_FOR_DOMAIN_NOT_FOUND_ERROR = 'uuid for domain is not found'
CONFIG_DIRECTORY_NOT_FOUND_ERROR = 'config directory is not found'
NODE_NOT_FOUND_ERROR = 'node is not found'
DOMAIN_NAME_FOR_UUID_NOT_FOUND_ERROR = 'uuid for domain is not found'
LIBVIRT_NODE_RUNNING_ERROR = 'libvirt node is not in shutoff state (for cloning state must be shutoff)'

BOX = 'box'

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
  new_libvirt_image_name = "#{path_to_new_config_directory}_#{node_name}_#{Time.now.to_i}"
  execute_bash "virt-clone -o #{full_domain_name} -n #{new_libvirt_image_name} --auto-clone"
  return new_libvirt_image_name
end


def replace_libvirt_node_id(path_to_nodes, node_name, id)
  set_node_machine_id(path_to_nodes, node_name, id)
end

def clone_libvirt_nodes(path_to_nodes, new_path_to_nodes)
  path_to_new_template = copy_old_template_to_new(path_to_nodes, new_path_to_nodes)
  nodes = get_nodes(path_to_nodes)
  nodes.each do |node_name|
    new_libvirt_image_name = create_libvirt_node_clone(path_to_nodes, node_name, new_path_to_nodes)
    new_uuid = get_libvirt_uuid_by_domain_name(new_libvirt_image_name)
    replace_libvirt_node_id(new_path_to_nodes, node_name, new_uuid)
  end
end

def copying_old_config_to_new(old_path, new_path)
  unless Dir.exists?(old_path)
    raise "Old config directory #{old_path} not found"
  end
  files = Dir.entries(old_path)
  if files.length == 2
    raise "In old config directory #{old_path} nodes are not found"
  end
  begin
    Dir.mkdir(new_path)
  rescue Errno::EEXIST
    raise "New config directory #{new_path} is existing"
  rescue SystemCallError
    raise "Not enough permissions in #{new_path}"
  end
  FileUtils.cp_r(old_path, new_path)
end

def copy_old_template_to_new(path_to_nodes, new_path_to_nodes)
  template_path = get_template_path path_to_nodes
  template_directory = get_template_directory path_to_nodes
  new_template_name = "#{new_path_to_nodes}.json"
  path_to_new_template = "#{template_directory}/#{new_template_name}"
  FileUtils.cp(template_path, path_to_new_template)
  return path_to_new_template
end

# rewrites template with changing box (on images created while making clone of node)
# for concrete node
def change_box_in_docker_template(template_path_of_cloned_config, node_name, new_box_name)
  template = JSON.parse(File.read(template_path_of_cloned_config))
  template[node_name][BOX] = new_box_name
  File.open(template_path_of_cloned_config, 'w') do |file|
    file.write(JSON.pretty_generate(template))
  end
end

def clone_docker_nodes(path_to_nodes, new_path_to_nodes, path_to_new_template)
  nodes = get_nodes(path_to_nodes)
  nodes.each do |node_name|
    new_docker_image_name = create_docker_node_clone(path_to_nodes, node_name, new_path_to_nodes)
    change_box_in_docker_template(path_to_new_template, node_name, new_docker_image_name)
  end
end

def generate_docker_machines(path_to_template, new_path_to_nodes)
  $session.configFile path_to_template
  $session.generate new_path_to_nodes
  $session.configFile = nil
end

def start_docker_machines(path_to_nodes)
  root_directory = Dir.pwd
  Dir.chdir path_to_nodes
  execute_bash('vagrant up --provider docker --no-provision')
  Dir.chdir root_directory
end

def replace_libvirt_template_path(path_to_nodes, new_template_path)
  template_path = get_template_path(path_to_nodes)
  File.open(template_path, 'w') { |file| file.write new_template_path }
end

def clone_nodes(path_to_nodes, new_path_to_nodes)
  path_to_new_template = copying_old_config_to_new(path_to_nodes, new_path_to_nodes)
  provider = get_provider(path_to_nodes)
  if provider == DOCKER
    clone_docker_nodes(path_to_nodes, new_path_to_nodes, path_to_new_template)
    generate_docker_machines(path_to_new_template, new_path_to_nodes)
    start_docker_machines(new_path_to_nodes)
  elsif provider == LIBVIRT
    clone_libvirt_nodes(path_to_nodes, new_path_to_nodes)
    replace_libvirt_template_path(new_path_to_nodes, path_to_new_template)
  else
    raise "#{provider}: provider does not support cloning"
  end
end

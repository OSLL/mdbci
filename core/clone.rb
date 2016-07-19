require 'fileutils'

require_relative 'out'
require_relative 'helper'
require 'fileutils'

UUID_FOR_DOMAIN_NOT_FOUND_ERROR = 'uuid for domain is not found'
CONFIG_DIRECTORY_NOT_FOUND_ERROR = 'config directory is not found'
NODE_NOT_FOUND_ERROR = 'node is not found'
DOMAIN_NAME_FOR_UUID_NOT_FOUND_ERROR = 'uuid for domain is not found'
LIBVIRT_NODE_RUNNING_ERROR = 'libvirt node is not in shutoff state (for cloning state must be shutoff)'
OLD_CONFIG_NOT_FULLY_CREATED = 'old config is not fully created'
NEW_CONFIG_DIRECTORY_EXISTS = 'new config directory already exists (remove it and try again)'

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

def copying_old_config_to_new(path_to_nodes, new_path_to_nodes)
  begin
    is_config_created(path_to_nodes)
  rescue Exception => e
    raise "#{path_to_nodes}: #{OLD_CONFIG_NOT_FULLY_CREATED} (#{e.message})"
  end
  raise NEW_CONFIG_DIRECTORY_EXISTS if Dir.exist? new_path_to_nodes
  $out.info "making copy of old config (#{path_to_nodes}) to new config (#{new_path_to_nodes})"
  FileUtils.cp_r(path_to_nodes, new_path_to_nodes)
end

def copy_old_template_to_new(path_to_nodes, new_path_to_nodes)
  template_path = get_template_path path_to_nodes
  template_directory = get_template_directory path_to_nodes
  new_template_name = "#{new_path_to_nodes}.json"
  new_path_template = "#{template_directory}/#{new_template_name}"
  $out.info "making copy of old template (#{template_path}) to new template (#{new_path_template})"
  FileUtils.cp(template_path, new_path_template)
  return new_path_template
end

# rewrites template with changing box (on images created while making clone of node)
# for concrete node
def change_box_in_docker_template(template_path_of_cloned_config, node_name, new_box_name)
  template = JSON.parse(File.read(template_path_of_cloned_config))
  template[node_name][BOX] = new_box_name
  $out.info "changing box for node: #{node_name} in template: #{template_path_of_cloned_config} to #{new_box_name}"
  File.open(template_path_of_cloned_config, 'w') do |file|
    file.write(JSON.pretty_generate(template))
  end
end

def clone_docker_nodes(path_to_nodes, new_path_to_nodes, path_to_new_template)
  nodes = get_nodes(path_to_nodes)
  nodes.each do |node_name|
    $out.info "making clone of node: #{path_to_nodes}/#{node_name}"
    new_docker_image_name = create_docker_node_clone(path_to_nodes, node_name, new_path_to_nodes)
    $out.info "cloning is done, new docker image name: #{new_docker_image_name}"
    change_box_in_docker_template(path_to_new_template, node_name, new_docker_image_name)
  end
end

def generate_docker_machines(path_to_template, new_path_to_nodes)
  $session.configFile path_to_template
  $session.generate new_path_to_nodes
  $session.configFile = nil
end

def start_docker_machines(path_to_nodes)
  $out.info "starting machines for config: #{path_to_nodes}"
  root_directory = Dir.pwd
  Dir.chdir path_to_nodes
  execute_bash('vagrant up --provider docker --no-provision')
  Dir.chdir root_directory
end

def replace_libvirt_template_path(path_to_nodes, new_template_path)
  $out.info "replacing path to template to new copied template path (#{new_template_path}) in #{path_to_nodes}/template"
  File.open("#{path_to_nodes}/template", 'w') { |file| file.write new_template_path }
end

def clone_nodes(path_to_nodes, new_path_to_nodes)
  path_to_new_template = copying_old_config_to_new(path_to_nodes, new_path_to_nodes)
  provider = get_provider(path_to_nodes)
  if provider == DOCKER
    $out.info "cloning docker machines from #{path_to_nodes} to #{new_path_to_nodes}"
    clone_docker_nodes(path_to_nodes, new_path_to_nodes, path_to_new_template)
    generate_docker_machines(path_to_new_template, new_path_to_nodes)
    start_docker_machines(new_path_to_nodes)
  elsif provider == LIBVIRT
    $out.info "cloning libvirt machines from #{path_to_nodes} to #{new_path_to_nodes}"
    clone_libvirt_nodes(path_to_nodes, new_path_to_nodes)
    replace_libvirt_template_path(new_path_to_nodes, path_to_new_template)
  else
    raise "#{provider}: provider does not support cloning"
  end
end

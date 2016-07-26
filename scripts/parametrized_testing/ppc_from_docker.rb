#!/usr/bin/ruby

require 'getoptlong'
require 'open3'
require 'json'
require 'fileutils'
require_relative '../../core/session'
require_relative '../../core/helper'

class PpcFromDocker

  CONFIG_ARGUMENT_REQUIRED_ERROR = 'you must provide config name'
  PARSE_OPTIONS_AND_ARGS_ERROR = 'wrong option'

  HELP_MESSAGE = <<-EOF
Script creates test mdbci boxes, that are made from docker running instances or removes them
Usage:
1) Generate mdbci(ppc) config from docker
    ./scripts/mdbci_from_docker.rb ORIGIN_DOCKER_CONFIG_NAME
2) Remove generated mdbci(ppc) config
    ./scripts/mdbci_from_docker.rb -r GENERATED_(MDBCI)PPC_CONFIG_NAME
Options:
    -r          remove generated mdbci config (and all leftovers)
Arguments:
    CONFIG_NAME    path to docker or (mdbci)ppc config
  EOF

  BOX_CONFIG_TEMPLATE = {
      :provider => 'mdbci',
      :IP => nil,
      :user => 'vagrant',
      :keyfile => nil,
      :platform => nil,
      :platform_version => nil
  }

  $is_for_removing = false

  attr_accessor :timestamp

  def initialize
    @timestamp = Time.now.strftime('%Y_%m_%d_%H_%M_%S')
  end

  def parse_options_and_args
    opts = GetoptLong.new(
        ['--help', '-h', GetoptLong::NO_ARGUMENT],
        ['--remove', '-r', GetoptLong::NO_ARGUMENT]
    )
    begin
      opts.each do |opt, _|
        case opt
          when '--help'
            puts HELP_MESSAGE
            exit
          when '--remove'
            $is_for_removing = true
          else
            raise PARSE_OPTIONS_AND_ARGS_ERROR
        end
      end
    end
    template = ARGV.shift
    raise CONFIG_ARGUMENT_REQUIRED_ERROR if template.to_s.empty?
    return template
  end

  def generate_removing_script(config_name_ppc_from_docker, path_to_boxes_file, paths_to_keyfiles)
    paths_to_keyfiles_array = Array.new
    paths_to_keyfiles.each do |path_to_keyfile|
      paths_to_keyfiles_array.push "\"#{path_to_keyfile}\""
    end
    paths_to_keyfiles_string = paths_to_keyfiles_array.join(', ')
    removing_script = <<EOF
require 'fileutils'
def remove_config
  [#{paths_to_keyfiles_string}].each { |path_to_keyfile| FileUtils.rm_rf(path_to_keyfile) }
  FileUtils.rm_rf('#{path_to_boxes_file}')
  FileUtils.rm_rf('#{config_name_ppc_from_docker}')
end
EOF
    File.open("#{config_name_ppc_from_docker}/remove_config_completely.rb", 'w') do |file|
      file.write removing_script
    end
  end

  # return tuple: origin docker config name. ppc config name generated from origin docker config
  def generate_ppc_environment(config_name_docker)
    config_name_mdbci_from_docker = "#{config_name_docker}_#{@timestamp}"
    paths_to_keyfiles = Array.new
    boxes_config = Hash.new
    template_path = get_template_path(config_name_docker)
    template_hash = JSON.parse(File.read(template_path))
    nodes_names = get_nodes(config_name_docker)
    nodes_names.each do |node_name|
      box_config = BOX_CONFIG_TEMPLATE.clone
      # Getting ip of node
      private_ip_output = execute_bash("./mdbci show private_ip #{config_name_docker}/#{node_name} --silent")
      box_config[:IP] = private_ip_output.to_s.split("\n")[-1]
      # Copying keyfile to KEYS directory and adding it to box config for current node)
      path_to_keyfile = "KEYS/#{node_name}_#{config_name_mdbci_from_docker}"
      paths_to_keyfiles.push(path_to_keyfile)
      File.open(path_to_keyfile, 'w') do |file|
        file.write(File.read("#{config_name_docker}/.vagrant/machines/#{node_name}/docker/private_key"))
      end
      box_config[:keyfile] = config_name_mdbci_from_docker
      # Getting platform and platform version
      box_name = execute_bash("./mdbci show box #{config_name_docker}/#{node_name} --silent")
      box_name = box_name.delete!("\n")
      boxes_hash = JSON.parse(File.read('BOXES/boxes_docker.json'))
      box_config[:platform] = boxes_hash[box_name]['platform']
      box_config[:platform_version] = boxes_hash[box_name]['platform_version']
      # Adding combining boxes configs
      new_box_name = "#{config_name_mdbci_from_docker}_#{node_name}"
      boxes_config[new_box_name] = box_config
      # Generating config for mdbci node
      template_hash[node_name]['box'] = new_box_name
    end
    # Saving boxes config to file
    path_to_boxes_file = "BOXES/#{config_name_mdbci_from_docker}.json"
    File.open(path_to_boxes_file, 'w') do |file|
      file.write(boxes_config.to_json)
    end
    # Creating configs for mdbci machines
    Dir.mkdir config_name_mdbci_from_docker
    File.open("#{config_name_mdbci_from_docker}/template.json", 'w') do |file|
      file.write(template_hash.to_json)
    end
    File.open("#{config_name_mdbci_from_docker}/mdbci_template", 'w') do |file|
      file.write("#{config_name_mdbci_from_docker}/template.json")
    end
    File.open("#{config_name_mdbci_from_docker}/provider", 'w') do |file|
      file.write('mdbci')
    end
    generate_removing_script(config_name_mdbci_from_docker, path_to_boxes_file, paths_to_keyfiles)
    return config_name_mdbci_from_docker
  end

  # file is not configured
  # it appears after ppc config being generated
  def remove_generated_ppc_environment(config_name_ppc_from_docker)
    require_relative "../#{config_name_ppc_from_docker}/remove_config_completely"
    remove_config
  end

end

if File.identical?(__FILE__, $0)
  ppc_from_docker = PpcFromDocker.new
  config_name = ppc_from_docker.parse_options_and_args
  if !$is_for_removing
    ppc_from_docker.generate_ppc_environment config_name
  else
    ppc_from_docker.remove_generated_ppc_environment config_name
  end
end

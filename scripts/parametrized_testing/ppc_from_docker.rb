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
Script creates test mdbci boxes/keys/config, that are made from docker running instances or removes them
Usage:
1) Generate mdbci(ppc) config from docker
    ./scripts/ppc_from_docker.rb -c ORIGIN_DOCKER_CONFIG_NAME
2) Generate mdbci(ppc) config from docker with given name
    ./scripts/ppc_from_docker.rb -a NEW_CONFIG_NAME ORIGIN_DOCKER_CONFIG_NAME
3) Remove generated mdbci(ppc) config
    ./scripts/ppc_from_docker.rb -r GENERATED_(MDBCI)PPC_CONFIG_NAME
Options:
    -r          remove generated mdbci config (and all leftovers)
    -c          creates new config
    -a          creates new config with given name
Arguments:
    CONFIG_NAME    path to docker or (mdbci)ppc configfig
  EOF

  BOX_CONFIG_TEMPLATE = {
      :provider => 'mdbci',
      :IP => nil,
      :user => 'vagrant',
      :keyfile => nil,
      :platform => nil,
      :platform_version => nil
  }

  attr_accessor :timestamp
  attr_accessor :is_for_removing
  attr_accessor :new_config_name

  def initialize
    @timestamp = Time.now.strftime('%Y_%m_%d_%H_%M_%S')
    @is_for_removing = false
    @new_config_name = nil
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
if File.identical?(__FILE__, $0)
  remove_config
end
EOF
    File.open("#{config_name_ppc_from_docker}/remove_config_completely.rb", 'w') do |file|
      file.write removing_script
    end
  end

  # return tuple: origin docker config name. ppc config name generated from origin docker config
  def generate_ppc_environment(config_name_docker, config_name_mdbci_from_docker)
    config_name_docker = config_name_docker.gsub(/\/+/, '')
    if config_name_mdbci_from_docker == nil
      config_name_mdbci_from_docker = "#{config_name_docker}_#{@timestamp}"
    end
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
      keyfile_name = "#{node_name}_#{config_name_mdbci_from_docker}"
      path_to_keyfile = "KEYS/#{keyfile_name}"
      paths_to_keyfiles.push(path_to_keyfile)
      File.open(path_to_keyfile, 'w') do |file|
        file.write(File.read("#{config_name_docker}/.vagrant/machines/#{node_name}/docker/private_key"))
      end
      File.chmod(0600, path_to_keyfile)
      box_config[:keyfile] = keyfile_name
      # Getting platform and platform version
      box_name = execute_bash("./mdbci show box #{config_name_docker}/#{node_name} --silent")
      box_name = box_name.delete!("\n")
      boxes_hash = Hash.new
      # Getting all boxes (also boxes for cloned docker machines)
      Dir.glob('BOXES/*').each { |boxes| boxes_hash = boxes_hash.merge(JSON.parse(File.read(boxes))) }
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
    load("#{File.realpath(config_name_ppc_from_docker)}/remove_config_completely.rb")
    remove_config
  end

  def parse_options_and_args
    opts = GetoptLong.new(
        ['--help', '-h', GetoptLong::NO_ARGUMENT],
        ['--remove', '-r', GetoptLong::NO_ARGUMENT],
        ['--create', '-c', GetoptLong::NO_ARGUMENT],
        ['--create-as', '-a', GetoptLong::REQUIRED_ARGUMENT],
    )
    begin
      opts.each do |opt, arg|
        case opt
          when '--help'
            puts HELP_MESSAGE
            exit
          when '--create'
            generate_ppc_environment(ARGV.shift, nil)
            exit
          when '--create-as'
            generate_ppc_environment(ARGV.shift, arg)
            exit
          when '--remove'
            remove_generated_ppc_environment(ARGV.shift)
            exit
          else
            raise PARSE_OPTIONS_AND_ARGS_ERROR
        end
      end
    end
  end

end

if File.identical?(__FILE__, $0)
  PpcFromDocker.new.parse_options_and_args
end

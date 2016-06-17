#!/usr/bin/ruby

require 'getoptlong'
require 'open3'
require 'json'

INFORMATION_TAG = 'INFO: '
ERROR_TAG = 'ERROR:'

TEMPLATE_ARGUMENT_REQUIRED_ERROR = 'You must provide template_path'

HELP_MESSAGE = <<-EOF
Script creates test mdbci boxes, that are made from docker running instances or removes them
Usage:
    ./scripts/mdbci_from_docker.rb TEMPLATE
Arguments:
    TEMPLATE    path to docker config template_path
EOF

GLOBAL_PREFIX_DOCKER_MACHINE = 'mdbci_testing_config_docker'
GLOBAL_PREFIX_MDBCI_FROM_DOCKER_MACHINE = 'mdbci_testing_config_mdbci_from_docker'

TEMPLATE_COOKBOOK_PATH = 'cookbook_path'
TEMPLATE_AWS_CONFIG = 'aws_config'

BOX_CONFIG_TEMPLATE = {
    :provider => "mdbci",
    :IP => nil,
    :user => "vagrant",
    :keyfile => nil,
    :platform => nil,
    :platform_version => nil
}

is_for_removing = false

def parse_options_and_args
  opts = GetoptLong.new(
      ['--help', '-h', GetoptLong::NO_ARGUMENT],
      ['--remove', '-r', GetoptLong::NO_ARGUMENT]
  )
  begin
    opts.each do |opt, arg|
      case opt
        when '--help'
          puts HELP_MESSAGE
          exit
        when '--remove'
          is_for_removing = true
      end
    end
  end
  template = ARGV.shift
  raise TEMPLATE_ARGUMENT_REQUIRED_ERROR if template.to_s.empty?
  return template
end

def execute_bash(cmd)
  output = ""
  process_status = Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thr|
    stdin.close
    stdout.each do |line|
      output = output + "\n" + line
      puts "#{INFORMATION_TAG} #{line}"
    end
    stdout.close
    stderr.each { |line| puts "#{ERROR_TAG} #{line}" }
    stderr.close
    wait_thr.value.exitstatus
  end
  raise "#{cmd} exited with non-zero exit code: #{process_status}" unless process_status == 0
  return process_status, output
end

def get_nodes(template_path)
  nodes = Array.new
  template = JSON.parse(File.read("#{template_path}"))
  template.each do |possible_node|
    if possible_node[0] != TEMPLATE_AWS_CONFIG and possible_node[0] != TEMPLATE_COOKBOOK_PATH
      nodes.push possible_node[0]
    end
  end
  raise NODES_NOT_FOUND_ERROR if nodes.empty?
  return nodes
end

def main
  template_path = parse_options_and_args
  nodes_names = get_nodes template_path
  config_name = File.basename("#{Dir.pwd}/#{template_path}", File.extname("#{Dir.pwd}/#{template_path}"))
  config_name_docker = "#{GLOBAL_PREFIX_DOCKER_MACHINE}_#{config_name}"
  config_name_mdbci_from_docker = "#{GLOBAL_PREFIX_MDBCI_FROM_DOCKER_MACHINE}_#{config_name}"
  # Starting docker machines
  execute_bash("./mdbci --template #{template_path} generate #{config_name_docker}")
  execute_bash("./mdbci up #{config_name_docker}")
  # Creating boxes config for running machines
  boxes_config = Hash.new
  config_hash = JSON.parse(File.read(template_path))
  nodes_names.each do |node_name|
    box_config = BOX_CONFIG_TEMPLATE.clone
    # Getting ip of node
    _, private_ip_output = execute_bash("./mdbci show private_ip #{config_name_docker}/#{node_name} --silent")
    box_config[:IP] = private_ip_output.to_s.split("\n")[-1]
    # Copying keyfile to KEYS directory and adding it to box config for current node
    _, box_name = execute_bash("./mdbci show box #{config_name_docker}/#{node_name} --silent")
    box_name = box_name.delete!("\n")
    File.open("KEYS/#{GLOBAL_PREFIX_MDBCI_FROM_DOCKER_MACHINE}_#{box_name}", 'w') do |file|
      file.write(File.read("#{config_name_docker}/.vagrant/machines/#{node_name}/docker/private_key"))
    end
    File.chmod(0400, "KEYS/#{GLOBAL_PREFIX_MDBCI_FROM_DOCKER_MACHINE}_#{box_name}")
    box_config[:keyfile] = "#{GLOBAL_PREFIX_MDBCI_FROM_DOCKER_MACHINE}_#{box_name}"
    # Getting platform and platform version
    boxes_hash = JSON.parse(File.read('BOXES/boxes_docker.json'))
    box_config[:platform] = boxes_hash[box_name]['platform']
    box_config[:platform_version] = boxes_hash[box_name]['platform_version']
    # Adding combining boxes configs
    boxes_config["#{GLOBAL_PREFIX_MDBCI_FROM_DOCKER_MACHINE}_#{box_name}"] = box_config
    # Generating config for mdbci node
    config_hash[node_name]['box'] = "#{GLOBAL_PREFIX_MDBCI_FROM_DOCKER_MACHINE}_#{box_name}"
  end
  # Saving boxes config to file
  File.open("BOXES/#{GLOBAL_PREFIX_MDBCI_FROM_DOCKER_MACHINE}.json", 'w') do |file|
    file.write(boxes_config.to_json)
  end
  # Creating configs for mdbci machines
  Dir.mkdir config_name_mdbci_from_docker
  File.open("#{config_name_mdbci_from_docker}/template.json", 'w') do |file|
    file.write(config_hash.to_json)
  end
  File.open("#{config_name_mdbci_from_docker}/mdbci_template", 'w') do |file|
    file.write("#{config_name_mdbci_from_docker}/template.json")
  end
  File.open("#{config_name_mdbci_from_docker}/provider", 'w') do |file|
    file.write('mdbci')
  end
end

if File.identical?(__FILE__, $0)
  main
end

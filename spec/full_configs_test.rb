require 'rspec'
require 'open3'
require 'fileutils'
require 'json'

GLOBAL_PREFIX = 'full_config_test'

TEMPLATE_COOKBOOK_PATH = 'cookbook_path'
TEMPLATE_AWS_CONFIG = 'aws_config'

NODES = %W(node0 node1 node2 node3 galera0 galera1 galera2 galera3 maxscale)
NODES_LITE = %W(node0 galera0 maxscale)

CONFIGS_DIRECTORY = 'confs'
CONFIGS = %W(aws aws_lite docker docker_lite libvirt libvirt_lite mdbci mdbci_lite)

AWS = 'aws'
DOCKER = 'docker'
VBOX = 'vbox'
LIBVIRT = 'libvirt'
MDBCI = 'mdbci'

def execute_bash(cmd)
  puts "Executing: [#{cmd}]"
  exit_code = Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thr|
    stdin.close
    stdout.each { |line| puts line }
    stdout.close
    stderr.each { |line| puts line }
    stderr.close
    wait_thr.value.exitstatus
  end
  return exit_code
end

def validate_template(template)
  return execute_bash("./mdbci validate_template --template #{template}")
end

def generate(template, config_name)
  return execute_bash("./mdbci --template #{template} generate #{config_name}")
end

def up(config_name)
  return execute_bash("./mdbci up #{config_name}")
end

def ssh(config_name)
  return execute_bash("./mdbci ssh --command ls #{config_name}")
end

def clean_environment
  CONFIGS.each do |config|
    config_directory = "#{GLOBAL_PREFIX}_#{config}"
    if Dir.exists?(config_directory)
      unless config_directory.include?(MDBCI)
        root_dir = Dir.pwd
        Dir.chdir config_directory
        execute_bash 'vagrant destroy -f'
        Dir.chdir root_dir
      end
      FileUtils.rm_rf config_directory
    end
  end
end

def get_nodes_names(template_path)
  nodes = Array.new
  template = JSON.parse(File.read(File.read(template_path)))
  template.each do |possible_node|
    if possible_node[0] != TEMPLATE_AWS_CONFIG and possible_node[0] != TEMPLATE_COOKBOOK_PATH
      nodes.push possible_node[0]
    end
  end
  return nodes
end

def get_boxes_by_config(template_path)
  boxes = Array.new
  template = JSON.parse(File.read(File.read(template_path)))
  template.each do |possible_node|
    if possible_node[0] != TEMPLATE_AWS_CONFIG and possible_node[0] != TEMPLATE_COOKBOOK_PATH
      boxes.push possible_node[1]['box']
    end
  end
  return boxes
end


describe nil do
  Dir.glob("#{CONFIGS_DIRECTORY}/*.json") do |template_path|
    config = File.basename(template_path, File.extname(template_path))
    generated_config_name = "#{GLOBAL_PREFIX}_#{config}"
    nodes = get_nodes_names(template_path)
    boxes = get_boxes_by_config(template_path)
    next if boxes.grep(/.*_#{VBOX}/).size > 0
    next if boxes.grep(/.*_#{MDBCI}/).size > 0
    before :all do
      clean_environment
    end
    after :all do
      clean_environment
    end
    it "Validating template: #{template_path}" do
      validate_template(template_path).should eql 0
    end
    it "Generating template: #{template_path} to config: #{generated_config_name}" do
      generate(template_path, generated_config_name).should eql 0
    end
    it "Starting config: #{generated_config_name}" do
      up(generated_config_name).should eql 0
    end
    nodes.each do |node_name|
      it "Running ssh command on nodes for config: #{generated_config_name}" do
        ssh("#{generated_config_name}/#{node_name}").should eql 0
      end
    end
  end
end

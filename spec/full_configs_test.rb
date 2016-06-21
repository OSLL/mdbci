GLOBAL_PREFIX = "full_config_test"
TEMPLATE_COOKBOOK_PATH = 'cookbook_path'
TEMPLATE_AWS_CONFIG = 'aws_config'

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

def find_nodes(config)
  nodes = Array.new
  template = JSON.parse(File.read(File.read("#{config}/template")))
  template.each do |possible_node|
    if possible_node[0] != TEMPLATE_AWS_CONFIG and possible_node[0] != TEMPLATE_COOKBOOK_PATH
      nodes.push possible_node[0]
    end
  end
  return nodes
end

def validate(tempate)
  return execute_bash("./mdbci validate_template #{template}")
end

def generate(template, conf_name)
  return execute_bash("./mdbci --template #{template} generate #{conf_name}")
end

def up(conf_name)
  return execute_bash("./mdbci up #{conf_name}")
end

def ssh(config)
  return execute_bash("./mdbci ssh --command ls #{conf_name}")
end

Dir.glob('confs/*.json') do |file|
  it "Validates template: #{file}" do
    validate(file).should eql 0
  end
  it "Generates template: #{file} to config: #{File.basename(file, File.extname(file))}" do
    validate(file).should eql 0
  end
  it "Starts config: #{File.basename(file, File.extname(file))}" do
    validate(file).should eql 0
  end
  it "Runs ssh command on nodes for config: #{File.basename(file, File.extname(file))}" do
    nodes_namesfind_nodes(File.basename(file, File.extname(file)))
    nodes_names.each_char do |node_name|
      ssh(node_name).should eql 0
    end
  end
end

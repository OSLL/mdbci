require_relative 'out'

TEMPLATE_COOKBOOK_PATH = 'cookbook_path'
TEMPLATE_AWS_CONFIG = 'aws_config'

MACHINE_NOT_CREATED_ERROR = 'machine is not created'
NODES_NOT_FOUND_ERROR = 'machines not found'
TEMPLATE_NOT_FOUND_ERROR = 'template not found'
NON_ZERO_BASH_EXIT_CODE_ERROR = 'command exited with non zero exit code'
MDBCI_MACHINE_HAS_NO_ID_ERROR = 'mdbci machine does not have id'
UNKNOWN_PROVIDER_ERROR = 'provider is unknown (file with provider definition is missing)'


def get_provider(path_to_nodes)

  begin
    return File.read "#{path_to_nodes}/provider"
  rescue
    raise "#{path_to_nodes} #{UNKNOWN_PROVIDER_ERROR}"
  end
end

def get_nodes(path_to_nodes)
  nodes = Array.new
  template = nil
  begin
    template = JSON.parse(File.read(File.read("#{path_to_nodes}/template")))
  rescue
    begin
      template = JSON.parse(File.read(File.read("#{path_to_nodes}/mdbci_template")))
    rescue
      raise $!, "#{path_to_nodes}/template or #{path_to_nodes}/mdbci_template #{TEMPLATE_NOT_FOUND_ERROR}", $1.backtrace
    end
  end
  template.each do |possible_node|
    if possible_node[0] != TEMPLATE_AWS_CONFIG and possible_node[0] != TEMPLATE_COOKBOOK_PATH
      nodes.push possible_node[0]
    end
  end
  raise "#{path_to_nodes}: #{NODES_NOT_FOUND_ERROR}" if nodes.empty?
  return nodes
end

# method gets ids of machines
def get_node_machine_id(path_to_nodes, node_name)
  provider = get_provider path_to_nodes
  if provider == 'mdbci'
    raise "#{path_to_nodes}/#{node_name}: #{MDBCI_MACHINE_HAS_NO_ID_ERROR}"
  end
  begin
    return File.read("#{path_to_nodes}/.vagrant/machines/#{node_name}/#{provider}/id")
  rescue Exception=>e
    raise $!, "#{path_to_nodes}/#{node_name}: #{MACHINE_NOT_CREATED_ERROR}", $!.backtrace
  end
end

# method returns bash command exit code
def execute_bash(cmd, silent = false)
  output = String.new
  process_status = nil
  begin
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
  rescue Exception=>e
    raise $!, "#{cmd}: #{NON_ZERO_BASH_EXIT_CODE_ERROR}", $!.backtrace
  end
  raise "#{cmd}: #{NON_ZERO_BASH_EXIT_CODE_ERROR} - #{process_status}" unless process_status == 0
  return output
end
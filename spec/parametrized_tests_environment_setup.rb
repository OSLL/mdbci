require_relative '../core/helper'
require_relative '../core/session'
require_relative '../core/out'
require_relative '../core/exception_handler'
require_relative '../core/snapshot'
require_relative '../scripts/run_docker_as_mdbci'

class ParametrizedTestingEnvironmentSetup

  CONFIG_PREFIX = 'mdbci_parametrized_test'
  NODE_ORIGIN_SNAPSHOT_INFIX = 'origin'
  FULL_NODE_ORIGIN_SNAPSHOT_PREFIX = "mdbci_snapshot_#{NODE_ORIGIN_SNAPSHOT_INFIX}"
  #PROVIDERS_SNAPSHOT_ENABLED = %W(docker vbox docker_for_ppc) ### virtualbox disabled (so far) ###
  PROVIDERS_SNAPSHOT_ENABLED = %W(docker libvirt)
  PPC = 'docker_for_ppc' ### docker_for_ppc is local analog for remote mdbci node ###
  AWS = 'aws'
  NODES = %W(node1 node2)
  PATH_TO_TEMPLATE = 'spec/test_machine_configurations'

  GLOBAL_PREFIX_DOCKER_MACHINE = 'mdbci_testing_config_docker'
  GLOBAL_PREFIX_MDBCI_FROM_DOCKER_MACHINE = 'mdbci_testing_config_mdbci_from_docker'

  def initialize
    initialize_mdbci_environment
  end

  def start_test(&block)
    prepare_snapshot_enabled_machines
    prepare_local_ppc_from_docker_machine
    prepare_aws_machine
    ret_val = block.call # calling test here
    destroy_aws_config
    return ret_val
  end

  def prepare_snapshot_enabled_machines
    configs_names = Array.new
    PROVIDERS_SNAPSHOT_ENABLED.each do |provider|
      config_name = "#{CONFIG_PREFIX}_#{provider}"
      configs_names.push config_name
      template_path = "#{PATH_TO_TEMPLATE}/#{config_name}.json"
      create_config(template_path, config_name) unless is_config_created config_name
      start_config(config_name) unless is_config_running config_name
      NODES.each do |node_name|
        snapshot_infix = NODE_ORIGIN_SNAPSHOT_INFIX
        full_snapshot_name = "#{FULL_NODE_ORIGIN_SNAPSHOT_PREFIX}_#{config_name}_#{node_name}"
        unless is_config_node_has_snapshot(config_name, node_name, full_snapshot_name)
          create_origin_snapshot(config_name, node_name, snapshot_infix)
        end
      end
    end
    return configs_names
  end

  def prepare_local_ppc_from_docker_machine
    config_name = "#{CONFIG_PREFIX}_#{PPC}"
    template_path = "#{PATH_TO_TEMPLATE}/#{config_name}.json"
    config_names = PpcFromDocker.new.prepare_mdbci_environment(template_path) unless is_config_created config_name
    return config_names
  end

  def prepare_aws_machine
    config_name = "#{CONFIG_PREFIX}_#{AWS}"
    template_path = "#{PATH_TO_TEMPLATE}/#{config_name}.json"
    create_config(template_path, config_name) unless is_config_created config_name
    start_config(config_name) unless is_config_running config_name
    return config_name
  end

  def destroy_aws_config
    config_name = "#{CONFIG_PREFIX}_#{AWS}"
    root_dir = Dir.pwd
    Dir.chdir config_name
    execute_bash('vagrant halt')
    Dir.chdir root_dir
  end

  def initialize_mdbci_environment
    $out = Out.new
    $session = Session.new
    $session.mdbciDir = Dir.pwd
    $exception_handler = ExceptionHandler.new
    $session.boxes = BoxesManager.new './BOXES'
    $session.repos = RepoManager.new './repo.d'
  end

  # true - all node are running, otherwise false
  def is_config_created(config_name)
    return false unless Dir.exist? config_name
    return true
  end

  def create_config(template_path, config_name)
    $session.configFile = template_path
    $session.generate config_name
    $session.configFile = nil
  end

  # true - node is running, otherwise false
  def is_config_node_running(config_name, node_name)
    root_dir = Dir.pwd
    Dir.chdir config_name
    output = execute_bash("vagrant status #{node_name}", true).to_s.split("\n")[2].split(/\s+/)
    Dir.chdir root_dir
    if output.to_a.size == 4 or output.to_a.size == 3 and output[1] != 'running'
      return false
    end
    return true
  end

  # true - all node are running, otherwise false
  def is_config_running(config_name)
    NODES.each do |node_name|
      return false unless is_config_node_running(config_name, node_name)
    end
    return true
  end

  def start_config(config_name)
    $session.up config_name
  end

  def get_snapshots_for_node(config_name, node_name)
    $session.path_to_nodes = config_name
    $session.node_name = node_name
    snapshots = Snapshot.new.get_snapshots node_name
    $session.path_to_nodes = nil
    $session.node_name = nil
    return snapshots
  end

  # true - origin snapshot created, otherwise false
  def is_config_node_has_snapshot(config_name, node_name, snapshot_name)
    snapshots = get_snapshots_for_node(config_name, node_name)
    return snapshots.include?(snapshot_name)
  end

  def create_origin_snapshot(config_name, node_name, snapshot_name)
    $session.path_to_nodes = config_name
    $session.node_name = node_name
    $session.snapshot_name = snapshot_name
    Snapshot.new.do('take')
    $session.path_to_nodes = nil
    $session.node_name = nil
    $session.snapshot_name = nil
  end

  def revert_to_origin_snapshot(config_name, node_name, snapshot_name)
    $session.path_to_nodes = config_name
    $session.node_name = node_name
    $session.snapshot_name = snapshot_name
    Snapshot.new.do('take')
    $session.path_to_nodes = nil
    $session.node_name = nil
    $session.snapshot_name = nil
  end

end

if File.identical?(__FILE__, $0)
  p = ParametrizedTestingEnvironmentSetup.new
  p.start_test {return 55}
end

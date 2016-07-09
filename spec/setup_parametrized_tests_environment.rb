require 'json'

require_relative '../core/helper'
require_relative '../core/session'
require_relative '../core/out'
require_relative '../core/exception_handler'
require_relative '../core/snapshot'
require_relative '../scripts/run_docker_as_mdbci'

class ParametrizedTestingEnvironmentSetup

  NODE_ORIGIN_SNAPSHOT_INFIX = 'origin'
  FULL_NODE_ORIGIN_SNAPSHOT_PREFIX = "mdbci_snapshot_#{NODE_ORIGIN_SNAPSHOT_INFIX}"
  PATH_TO_TEMPLATES = 'spec/parametrized_tests_templates'
  CONFIG_PREFIX = 'mdbci_parametrized_test'

  # configs
  DOCKER = 'docker'
  LIBVIRT = 'libvirt'
  VIRTUALBOX = 'virtualbox'
  PPC = 'docker_for_ppc'
  AWS = 'aws'

  def initialize
    initialize_mdbci_environment
  end

  def start_test(&block)
    configs_names = Array.new

    # generating and starting all configs
    configs_names.push prepare_config "#{CONFIG_PREFIX}_#{DOCKER}"
    configs_names.push prepare_config "#{CONFIG_PREFIX}_#{LIBVIRT}"
    # prepare_config "#{CONFIG_PREFIX}_#{VIRTUALBOX}"
    configs_names.concat prepare_local_ppc_from_docker_config "#{CONFIG_PREFIX}_#{PPC}"
    configs_names.push prepare_aws_machine "#{CONFIG_PREFIX}_#{AWS}"

    # create_metadata configs_names

    # running tests
    ret_val = block.call

    # destroying vagrant machine
    # destroy_aws_config "#{CONFIG_PREFIX}_#{AWS}"

    # test result for jenkins
    return ret_val
  end

  # method for providers: docker, libvirt, virtualbox
  def prepare_config(config_name)
    template_path = "#{PATH_TO_TEMPLATES}/#{config_name}.json"
    create_config(template_path, config_name) unless is_config_created config_name
    start_config(config_name) unless is_config_running config_name
    prepare_snapshots(config_name)
    return config_name
  end

  # method for provider: mdbci (docker_for_ppc)
  # return config names or nil if config already created
  def prepare_local_ppc_from_docker_config(config_name)
    template_path = "#{PATH_TO_TEMPLATES}/#{config_name}.json"
    docker_config_name, ppc_config_name = PpcFromDocker.new.prepare_mdbci_environment(template_path)
    prepare_snapshots(docker_config_name)
    return [docker_config_name, ppc_config_name]
  end

  def prepare_snapshots(config_name)
    nodes = get_nodes config_name
    nodes.each do |node_name|
      full_snapshot_name = "#{FULL_NODE_ORIGIN_SNAPSHOT_PREFIX}_#{config_name}_#{node_name}"
      if !is_config_node_has_snapshot(config_name, node_name, full_snapshot_name)
        create_origin_snapshot(config_name, node_name, NODE_ORIGIN_SNAPSHOT_INFIX)
      else
        revert_to_origin_snapshot(config_name, node_name, NODE_ORIGIN_SNAPSHOT_INFIX)
      end
    end
  end

  def prepare_aws_machine(config_name)
    template_path = "#{PATH_TO_TEMPLATES}/#{config_name}.json"
    create_config(template_path, config_name) unless is_config_created config_name
    start_config(config_name) unless is_config_running config_name
    return config_name
  end

  def destroy_aws_config(config_name)
    root_dir = Dir.pwd
    Dir.chdir config_name
    execute_bash('vagrant destroy -f')
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
    output = execute_bash("vagrant status #{node_name}", true) rescue nil
    return false unless output
    output = output.to_s.split("\n")[2].split(/\s+/)
    Dir.chdir root_dir
    if output.to_a.size == 4 or output.to_a.size == 3 and output[1] != 'running'
      return false
    end
    return true
  end

  # true - all node are running, otherwise false
  def is_config_running(config_name)
    nodes = get_nodes config_name rescue nil
    return false unless nodes
    nodes.each do |node_name|
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
    Snapshot.new.take_snapshot(node_name, snapshot_name)
    $session.path_to_nodes = nil
  end

  def revert_to_origin_snapshot(config_name, node_name, snapshot_name)
    $session.path_to_nodes = config_name
    Snapshot.new.revert_snapshot(node_name, snapshot_name)
    $session.path_to_nodes = nil
  end

  def create_metadata(configs_names)
    metadata = Hash.new
    metadata[:configs] = Array.new
    configs_names.each do |config_name|
      nodes_names = get_nodes config_name rescue nil
      provider = get_provider config_name rescue nil
      metadata_nodes = Array.new
      nodes_names.each do |node_name|
        node_id = nil
        unless provider == 'mdbci'
          node_id = get_node_machine_id(config_name, node_name) rescue nil
        end
        snapshots = get_snapshots_for_node(config_name, node_name) rescue nil
        metadata_nodes.push({
                                :node_name => node_name,
                                :node_id => node_id,
                                :node_snapshots => snapshots
                            })
      end
      metadata[:configs] << {
          :config_name => config_name,
          :config_provider => provider,
          :config_nodes => metadata_nodes
      }
      metadata[:creation_timestamp] = Time.now.to_i
    end
    puts JSON.pretty_generate(metadata)
    File.open('metadata', 'w') do |file|
      file.write(JSON.pretty_generate(metadata))
    end
    return metadata
  end

end

if File.identical?(__FILE__, $0)
  p = ParametrizedTestingEnvironmentSetup.new
  p.start_test { puts 'WORKS'; 1 }
end

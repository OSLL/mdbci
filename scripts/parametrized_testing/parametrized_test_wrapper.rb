require 'fileutils'

require_relative '../../core/session'
require_relative '../../core/out'
require_relative '../../core/snapshot'
require_relative '../../core/helper'
require_relative '../../core/clone'
require_relative '../../core/exception_handler'

class ParametrizedTestWrapper

  CONFIG_PREFIX = 'mdbci_param_test'
  CLONED_CONFIG_INFIX = 'clone'

  DOCKER = 'docker'
  LIBVIRT = 'libvirt'
  VIRTUALBOX = 'virtualbox'
  AWS = 'aws'
  DOCKER_FOR_PPC = 'docker_for_ppc'
  PPC_FROM_DOCKER = 'ppc_from_docker'

=begin
  def initialize
    at_exit{
      remove_clones
    }
  end
=end

  def initialize_mdbci_environment_variables
    $out = Out.new
    $session = Session.new
    $session.md bciDir = Dir.pwd
    $exception_handler = ExceptionHandler.new
    $session.boxes = BoxesManager.new './BOXES'
    $session.repos = RepoManager.new './repo.d'
  end

  def remove_mdbci_environment_variables
    $out = nil
    $session.mdbciDir = nil
    $exception_handler = nil
    $session.boxes = nil
    $session.repos = nil
    $session = nil
  end

  # block must not has return statement, because it will cause exception (LocalJump)
  # to make block return something just add variable as last statement in block
  def mdbci_environment_variables_wrapper(&block)
    initialize_mdbci_environment_variables
    return_value = block.call
    remove_mdbci_environment_variables
    return return_value
  end

  def create_clone(config_name, cloned_config_name)
    puts "Cloning #{config_name} to #{cloned_config_name}"
    mdbci_environment_variables_wrapper {
      $session.clone(config_name, cloned_config_name)
    }
  end

  def create_ppc_from_docker_config(config_name_docker, config_name_ppc)
    puts "Creating ppc config: #{config_name_ppc} from docker config: #{config_name_docker}"
    return PpcFromDocker.new.generate_ppc_environment(config_name_docker, config_name_ppc)
  end

  def remove_ppc_from_docker_config(config_name_ppc)
    puts "Removing ppc config: #{config_name_ppc}"
    PpcFromDocker.new.remove_generated_ppc_environment(config_name_ppc)
  end

  def get_snapshots_for_node(config_name, node_name)
    return mdbci_environment_variables_wrapper {
      $session.path_to_nodes = config_name
      snapshots = Snapshot.new.get_snapshots node_name
      $session.path_to_nodes = nil
      snapshots
    }
  end

  def remove_snapshots_for_node(config_name, node_name)
    puts "Removing snapshots for machine: #{config_name}/#{node_name}"
    snapshots = get_snapshots_for_node(config_name, node_name)
    snapshots.each do |snapshot_name|
      mdbci_environment_variables_wrapper {
        $session.path_to_nodes = config_name
        Snapshot.new.remove_snapshot(node_name, snapshot_name) rescue nil
        $session.path_to_nodes = nil
      }
    end
  end

  def prepare_ppc_clone
    config_docker_for_ppc = "#{CONFIG_PREFIX}_#{DOCKER_FOR_PPC}"
    cloned_config_docker_for_ppc = "#{CONFIG_PREFIX}_#{CLONED_CONFIG_INFIX}_#{DOCKER_FOR_PPC}"
    create_clone(config_docker_for_ppc, cloned_config_docker_for_ppc)
    cloned_config_ppc_from_docker = "#{CONFIG_PREFIX}_#{CLONED_CONFIG_INFIX}_#{PPC_FROM_DOCKER}"
    create_ppc_from_docker_config(cloned_config_docker_for_ppc, cloned_config_ppc_from_docker)
  end

  def remove_ppc_clone
    cloned_config_ppc_from_docker = "#{CONFIG_PREFIX}_#{CLONED_CONFIG_INFIX}_#{PPC_FROM_DOCKER}"
    remove_ppc_from_docker_config(cloned_config_ppc_from_docker)
    cloned_config_docker_for_ppc = "#{CONFIG_PREFIX}_#{CLONED_CONFIG_INFIX}_#{DOCKER_FOR_PPC}"
    nodes = get_nodes(cloned_config_docker_for_ppc)
    docker_images = Array.new
    nodes.each { |node_name| docker_images.concat(get_snapshots_for_node(cloned_config_docker_for_ppc, node_name)) }
    destroy_config(cloned_config_docker_for_ppc)
    docker_images.each { |docker_image| execute_bash("docker rmi #{docker_image}") }
    # removing clone leftovers
    Dir.glob('BOXES/fake_docker_boxes_*').each do |fake_box|
      FileUtils.rm_rf(fake_box)
    end
  end

  def prepare_clones
    create_clone("#{CONFIG_PREFIX}_#{DOCKER}", "#{CONFIG_PREFIX}_#{CLONED_CONFIG_INFIX}_#{DOCKER}")
    create_clone("#{CONFIG_PREFIX}_#{LIBVIRT}", "#{CONFIG_PREFIX}_#{CLONED_CONFIG_INFIX}_#{LIBVIRT}")
    prepare_ppc_clone
  end

  def remove_clones
    destroy_config("#{CONFIG_PREFIX}_#{CLONED_CONFIG_INFIX}_#{DOCKER}")
    destroy_config("#{CONFIG_PREFIX}_#{CLONED_CONFIG_INFIX}_#{LIBVIRT}")
    remove_ppc_clone
  end

  def cleanup_before_removing_clones
    FileUtils.rm_rf(get_template_path("#{CONFIG_PREFIX}_#{CLONED_CONFIG_INFIX}_#{DOCKER}"))
    FileUtils.rm_rf(get_template_path("#{CONFIG_PREFIX}_#{CLONED_CONFIG_INFIX}_#{LIBVIRT}"))
  end

end
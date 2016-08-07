require 'fileutils'

require_relative '../../core/session'
require_relative '../../core/out'
require_relative '../../core/snapshot'
require_relative '../../core/helper'
require_relative '../../core/clone'
require_relative '../../core/exception_handler'
require_relative 'ppc_from_docker'

class ParametrizedTestWrapper

  CONFIG_PREFIX = 'mdbci_param_test'
  CLONED_CONFIG_INFIX = 'clone'

  DOCKER = 'docker'
  LIBVIRT = 'libvirt'
  VIRTUALBOX = 'virtualbox'
  AWS = 'aws'
  DOCKER_FOR_PPC = 'docker_for_ppc'
  PPC_FROM_DOCKER = 'ppc_from_docker'

  attr_accessor :old_session

  def initialize_mdbci_environment_variables
    $old_session = $session
    $out = Out.new
    $session = Session.new
    $session.mdbciDir = Dir.pwd
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
    $session = $old_session
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
    out_info "Cloning #{config_name} to #{cloned_config_name}"
    mdbci_environment_variables_wrapper {
      $session.clone(config_name, cloned_config_name)
    }
  end

  def create_ppc_from_docker_config(config_name_docker, config_name_ppc)
    out_info "Creating ppc config: #{config_name_ppc} from docker config: #{config_name_docker}"
    return PpcFromDocker.new.generate_ppc_environment(config_name_docker, config_name_ppc)
  end

  def remove_ppc_from_docker_config(config_name_ppc)
    out_info "Removing ppc config: #{config_name_ppc}"
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

  def remove_docker_images(images)
    images.each { |image| execute_bash("docker rmi #{image}") rescue nil }
  end

  def prepare_ppc_clone
    config_docker_for_ppc = "#{CONFIG_PREFIX}_#{DOCKER_FOR_PPC}"
    cloned_config_docker_for_ppc = "#{CONFIG_PREFIX}_#{CLONED_CONFIG_INFIX}_#{DOCKER_FOR_PPC}"
    create_clone(config_docker_for_ppc, cloned_config_docker_for_ppc)
    cloned_config_ppc_from_docker = "#{CONFIG_PREFIX}_#{CLONED_CONFIG_INFIX}_#{PPC_FROM_DOCKER}"
    create_ppc_from_docker_config(cloned_config_docker_for_ppc, cloned_config_ppc_from_docker)
  end

  def destroy_docker_config(config_name)
    docker_images = Array.new
    get_nodes(config_name).each do |node_name|
      docker_images.concat(get_snapshots_for_node(config_name, node_name))
    end
    destroy_config(config_name)
    remove_docker_images(docker_images)
  end

  def remove_ppc_clone
    cloned_config_ppc_from_docker = "#{CONFIG_PREFIX}_#{CLONED_CONFIG_INFIX}_#{PPC_FROM_DOCKER}"
    remove_ppc_from_docker_config(cloned_config_ppc_from_docker)
    cloned_config_docker_for_ppc = "#{CONFIG_PREFIX}_#{CLONED_CONFIG_INFIX}_#{DOCKER_FOR_PPC}"
    template_docker = get_template_path(cloned_config_docker_for_ppc)
    destroy_docker_config(cloned_config_docker_for_ppc)
    FileUtils.rm_rf(template_docker)
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
    template_docker = get_template_path("#{CONFIG_PREFIX}_#{CLONED_CONFIG_INFIX}_#{DOCKER}")
    destroy_docker_config("#{CONFIG_PREFIX}_#{CLONED_CONFIG_INFIX}_#{DOCKER}")
    template_libvirt = get_template_path("#{CONFIG_PREFIX}_#{CLONED_CONFIG_INFIX}_#{LIBVIRT}")
    destroy_config("#{CONFIG_PREFIX}_#{CLONED_CONFIG_INFIX}_#{LIBVIRT}")
    FileUtils.rm_rf(template_docker)
    FileUtils.rm_rf(template_libvirt)
    remove_ppc_clone
  end

end
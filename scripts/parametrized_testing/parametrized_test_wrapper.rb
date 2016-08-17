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
  PPC = 'ppc'
  DOCKER_FOR_PPC = 'docker_for_ppc'
  PPC_FROM_DOCKER = 'ppc_from_docker'

  CONFIG_DOCKER = "#{CONFIG_PREFIX}_#{DOCKER}"
  CONFIG_LIBVIRT = "#{CONFIG_PREFIX}_#{LIBVIRT}"
  CONFIG_DOCKER_FOR_PPC = "#{CONFIG_PREFIX}_#{DOCKER_FOR_PPC}"
  CONFIG_PPC_FROM_DOCKER = "#{CONFIG_PREFIX}_#{PPC_FROM_DOCKER}"
  CONFIG_AWS = "#{CONFIG_PREFIX}_#{AWS}"
  CONFIG_VIRTUAL_BOX = "#{CONFIG_PREFIX}_#{VIRTUALBOX}"

  CLONE_CONFIG_DOCKER = "#{CONFIG_PREFIX}_#{CLONED_CONFIG_INFIX}_#{DOCKER}"
  CLONE_CONFIG_LIBVIRT = "#{CONFIG_PREFIX}_#{CLONED_CONFIG_INFIX}_#{LIBVIRT}"
  CLONE_CONFIG_DOCKER_FOR_PPC = "#{CONFIG_PREFIX}_#{CLONED_CONFIG_INFIX}_#{DOCKER_FOR_PPC}"
  CLONE_CONFIG_PPC_FROM_DOCKER = "#{CONFIG_PREFIX}_#{CLONED_CONFIG_INFIX}_#{PPC_FROM_DOCKER}"
  CLONE_CONFIG_VIRTUAL_BOX = "#{CONFIG_PREFIX}_#{CLONED_CONFIG_INFIX}_#{VIRTUALBOX}"

  attr_accessor :old_session

  def initialize
    at_exit{remove_clones([DOCKER, LIBVIRT, PPC])}
  end

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
      Clone.new.clone_nodes(config_name, cloned_config_name, true)
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
    create_clone(CONFIG_DOCKER_FOR_PPC, CLONE_CONFIG_DOCKER_FOR_PPC)
    create_ppc_from_docker_config(CLONE_CONFIG_DOCKER_FOR_PPC, CLONE_CONFIG_PPC_FROM_DOCKER)
  end

  def destroy_docker_config(config_name)
    docker_images = Array.new
    nodes = get_nodes(config_name) rescue nil
    unless nodes.nil?
      get_nodes(config_name).each do |node_name|
        docker_images.concat(get_snapshots_for_node(config_name, node_name))
      end
    end
    destroy_config(config_name) rescue nil
    remove_docker_images(docker_images)
  end

  def remove_ppc_clone
    remove_ppc_from_docker_config(CLONE_CONFIG_PPC_FROM_DOCKER) rescue nil
    template_docker = get_template_path(CLONE_CONFIG_DOCKER_FOR_PPC) rescue nil
    destroy_docker_config(CLONE_CONFIG_DOCKER_FOR_PPC)
    FileUtils.rm_rf(template_docker) unless template_docker.nil?
    Dir.glob('BOXES/fake_docker_boxes_*').each do |fake_box|
      FileUtils.rm_rf(fake_box)
    end
  end

  def prepare_clones(configs_providers)
    create_clone(CONFIG_DOCKER, CLONE_CONFIG_DOCKER) if configs_providers.include? DOCKER
    create_clone(CONFIG_LIBVIRT, CLONE_CONFIG_LIBVIRT) if configs_providers.include? LIBVIRT
    prepare_ppc_clone if configs_providers.include? PPC
  end

  def remove_clones(configs_providers)
    if configs_providers.include? DOCKER
      template_docker = get_template_path(CLONE_CONFIG_DOCKER) rescue nil
      destroy_docker_config(CLONE_CONFIG_DOCKER)
      FileUtils.rm_rf(template_docker) unless template_docker.nil?
    end
    if configs_providers.include? LIBVIRT
      template_libvirt = get_template_path(CLONE_CONFIG_LIBVIRT) rescue nil
      destroy_config(CLONE_CONFIG_LIBVIRT) rescue nil
      FileUtils.rm_rf(template_libvirt) unless template_libvirt.nil?
    end
    remove_ppc_clone if configs_providers.include? PPC
  end

end
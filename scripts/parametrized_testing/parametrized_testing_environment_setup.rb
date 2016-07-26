require 'json'
require 'fileutils'

require_relative '../../core/helper'
require_relative '../../core/session'
require_relative '../../core/out'
require_relative '../../core/exception_handler'
require_relative '../../core/snapshot'
require_relative 'ppc_from_docker'

class ParametrizedTestingEnvironmentSetup

  PATH_TO_TEMPLATES = 'spec/parametrized_tests_templates'
  PATH_TO_METADATA = 'parametrized_tests_metadata'
  CONFIG_PREFIX = 'mdbci_parametrized_test'
  BACKUP_CONFIG_POSTFIX = 'backup'

  # configs
  DOCKER = 'docker'
  LIBVIRT = 'libvirt'
  VIRTUALBOX = 'virtualbox'
  PPC = 'docker_for_ppc'
  AWS = 'aws'

  attr_accessor :current_metadata

  def initialize
    initialize_mdbci_environment
  end

  def initialize_mdbci_environment
    unless $mdbci_environment_initialized
      $out = Out.new
      $session = Session.new
      $session.mdbciDir = Dir.pwd
      $exception_handler = ExceptionHandler.new
      $session.boxes = BoxesManager.new './BOXES'
      $session.repos = RepoManager.new './repo.d'
      $mdbci_environment_initialized = true
    end
  end

  def remove_mdbci_environment
    if $mdbci_environment_initialized
      $out = nil
      $session.mdbciDir = nil
      $exception_handler = nil
      $session.boxes = nil
      $session.repos = nil
      $session = nil
      $mdbci_environment_initialized = false
    end
  end

  def generate_config(template_path, config_name)
    $session.configFile = template_path
    $session.generate config_name
    $session.configFile = nil
  end

  def up_config(config_name)
    $session.up config_name
  end

  def clone_config(origin_config, testing_config)
    $session.clone(origin_config, testing_config)
  end

  def complete_restart_origin_config(template_path, config_name)
    destroy_config(config_name)
    generate_config(template_path, config_name)
    up_config(config_name)
  end

  def backup_exists(config_name)
    return Dir.exist?("#{config_name}_#{BACKUP_CONFIG_POSTFIX}")
  end

  def create_backup(config_name)
    $out.info "Creating backup for #{config_name}"
    backup_name = "#{config_name}_#{BACKUP_CONFIG_POSTFIX}"
    FileUtils.mkdir_p(backup_name)
    FileUtils.cp_r(Dir.glob("#{config_name}/*"), backup_name)
  end

  def restore_backup(config_name)
    $out.info "Restoring backup for #{config_name}"
    backup_name = "#{config_name}_#{BACKUP_CONFIG_POSTFIX}"
    FileUtils.cp_r(Dir.glob("#{backup_name}/*"), config_name)
  end

  def remove_backup(config_name)
    $out.info "Removing backup for #{config_name}"
    backup_name = "#{config_name}_#{BACKUP_CONFIG_POSTFIX}"
    FileUtils.rm_rf(backup_name)
  end

  def are_config_files_valid(config_name)
    config_files_ok = true
    $out.warning "Checking files for #{config_name}"
    config_files_ok = false unless is_config_created(config_name)
    if !config_files_ok
      $out.warning "Some files are missing in #{config_name}, trying backup"
      if backup_exists(config_name)
        $out.warning "Backup with all files exists for config #{config_name}"
        restore_backup(config_name)
        remove_backup(config_name)
        $out.warning "Backup restored and removed for config #{config_name}"
        if is_config_created(config_name)
          $out.info "Backup helped, config directory #{config_name} is fine"
          config_files_ok = true
        else
          $out.warning "Backup did not help, config #{config_name} is broken"
          config_files_ok = false
        end
      else
        $out.warning "Backup does not exists for #{config_name}"
        config_files_ok = false
      end
    else
      $out.info "Config directory #{config_name} is fine"
      config_files_ok = true
    end
    return config_files_ok
  end

  def is_config_state_valid(config_name)
    config_state_ok = true
    # checking machine activity
    $out.warning "Checking that config #{config_name} is running"
    unless is_config_running(config_name)
      $out.warning "Config #{config_name} is not running"
      begin
        $out.warning "Trying to start config #{config_name}"
        start_config(config_name, false, true)
        unless is_config_running(config_name)
          $out.warning "Config #{config_name} is not running"
          config_state_ok = false
        end
      rescue Exception => e
        $out.error "Failed to start config #{config_name}"
        e.message.each_line { |line| $out.error line }
        config_state_ok = false
      end
    end
    return config_state_ok
  end

  # method for providers: docker, libvirt, virtualbox
  def prepare_origin_config(template_path, config_name)
    config_files_ok = false
    config_state_ok = false
    if Dir.exist?(config_name)
      # checking for missing files
      config_files_ok = are_config_files_valid(config_name)
      config_state_ok = is_config_state_valid(config_name) if config_files_ok
    end
    if !config_files_ok or !config_state_ok
      $out.warning "Config #{config_name} is not operable. Restarting config completely"
      complete_restart_origin_config(template_path, config_name)
      unless is_config_running(config_name)
        raise "failed to start config #{config_name}, check config manually"
      end
    end
    $out.info "Config #{config_name} is running"
    create_backup(config_name)
  end

  def create_ppc_from_docker_config(docker_config_name)
    return PpcFromDocker.new.generate_ppc_environment(docker_config_name)
  end

  def prepare_aws_machine(config_name)
    template_path = "#{PATH_TO_TEMPLATES}/#{config_name}.json"
    generate_config(template_path, config_name) unless is_config_created config_name
    start_config(config_name, AWS) unless is_config_stopped config_name
    return config_name
  end

  def get_snapshots_for_node(config_name, node_name)
    $session.path_to_nodes = config_name
    $session.node_name = node_name
    snapshots = Snapshot.new.get_snapshots node_name
    $session.path_to_nodes = nil
    $session.node_name = nil
    return snapshots
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
    return metadata
  end

  def prepare_mdbci_environment
    # preparing docker and libvirt configs
    prepare_origin_config("#{PATH_TO_TEMPLATES}/#{DOCKER}.json", "#{CONFIG_PREFIX}_#{DOCKER}")
    prepare_origin_config("#{PATH_TO_TEMPLATES}/#{LIBVIRT}.json", "#{CONFIG_PREFIX}_#{LIBVIRT}")
    # preparing ppc config
    config_ppc_from_docker = "#{CONFIG_PREFIX}_#{PPC}"
    prepare_origin_config("#{PATH_TO_TEMPLATES}/#{PPC}.json", config_ppc_from_docker)
    create_ppc_from_docker_config(config_ppc_from_docker)
  end

end

if File.identical?(__FILE__, $0)
  ParametrizedTestingEnvironmentSetup.new.prepare_mdbci_environment
end

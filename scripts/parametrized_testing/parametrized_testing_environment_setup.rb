require 'json'
require 'fileutils'

require_relative '../../core/helper'
require_relative '../../core/session'
require_relative '../../core/out'
require_relative '../../core/exception_handler'
require_relative '../../core/snapshot'
require_relative '../../core/constants'
require_relative 'ppc_from_docker'

class ParametrizedTestingEnvironmentSetup

  PARSE_OPTIONS_AND_ARGS_ERROR = 'wrong option'

  PATH_TO_TEMPLATES = 'spec/parametrized_tests_templates'
  CONFIG_PREFIX = 'mdbci_param_test'
  BACKUP_CONFIG_POSTFIX = 'backup'

  CONFIG_DOCKER = "#{CONFIG_PREFIX}_#{DOCKER}"
  CONFIG_LIBVIRT = "#{CONFIG_PREFIX}_#{LIBVIRT}"
  CONFIG_VIRTUALBOX = "#{CONFIG_PREFIX}_#{VIRTUALBOX}"
  CONFIG_DOCKER_FOR_PPC = "#{CONFIG_PREFIX}_#{DOCKER_FOR_PPC}"
  CONFIG_AWS = "#{CONFIG_PREFIX}_#{AWS}"

  TEMPLATE_DOCKER = "#{PATH_TO_TEMPLATES}/#{DOCKER}.json"
  TEMPLATE_LIBVIRT = "#{PATH_TO_TEMPLATES}/#{LIBVIRT}.json"
  TEMPLATE_VIRTUALBOX = "#{PATH_TO_TEMPLATES}/#{VIRTUALBOX}.json"
  TEMPLATE_DOCKER_FOR_PPC = "#{PATH_TO_TEMPLATES}/#{DOCKER_FOR_PPC}.json"
  TEMPLATE_AWS = "#{PATH_TO_TEMPLATES}/#{AWS}.json"

  HELP_MESSAGE = <<-EOF
Script creates, resumes or stops mdbci parametrized testing environment
Usage:
    ./scripts/parametrized_testing_environment.rb  [-p PATH_TO_TEMPLATES]
Options:
    -r          remove generated mdbci config (and all leftovers)
    -p          pause
    -s          start/resume
    -h          this help message
Arguments:
    CONFIG_NAME    path to docker or (mdbci)ppc config
  EOF

  attr_accessor :is_for_removing
  attr_accessor :is_for_stopping

  def initialize
    initialize_mdbci_environment_variables
  end

  def initialize_mdbci_environment_variables
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

  def generate_config(template_path, config_name)
    $session.configFile = template_path
    $session.generate config_name
    $session.configFile = nil
  end

  def up_config(config_name)
    $session.up config_name
  end

  def clone_config(origin_config, testing_config)
    $session.clone_config(origin_config, testing_config)
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
    $out.warning "Checking that config #{config_name} has ever started"
    unless is_config_ever_started(config_name)
      $out.warning "Config #{config_name} has never been started (machine state is equivalent for vagrant 'not created' state)"
      return false
    end
    $out.warning "Checking that config #{config_name} is running"
    unless is_config_running(config_name)
      $out.warning "Config #{config_name} is not running"
      begin
        $out.warning "Trying to start config #{config_name} in no-parallel mode"
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

  def prepare_mdbci_environment
    prepare_origin_config(TEMPLATE_DOCKER, CONFIG_DOCKER)
    prepare_origin_config(TEMPLATE_LIBVIRT, CONFIG_LIBVIRT)
    prepare_origin_config(TEMPLATE_DOCKER_FOR_PPC, CONFIG_DOCKER_FOR_PPC)
  end

  def stop_mdbci_environment
    stop_config(CONFIG_DOCKER)
    stop_config(CONFIG_LIBVIRT)
    stop_config(CONFIG_DOCKER_FOR_PPC)
  end

  def remove_mdbci_environment
    Dir.glob('*_network_config').each { |nc| FileUtils.rm_rf(nc) }
    remove_backup(CONFIG_DOCKER) if backup_exists(CONFIG_DOCKER)
    destroy_config(CONFIG_DOCKER)
    remove_backup(CONFIG_LIBVIRT) if backup_exists(CONFIG_LIBVIRT)
    destroy_config(CONFIG_LIBVIRT)
    remove_backup(CONFIG_DOCKER_FOR_PPC) if backup_exists(CONFIG_DOCKER_FOR_PPC)
    destroy_config(CONFIG_DOCKER_FOR_PPC)
  end

  def parse_options_and_args
    opts = GetoptLong.new(
        ['--help', '-h', GetoptLong::NO_ARGUMENT],
        ['--start', '-s', GetoptLong::NO_ARGUMENT],
        ['--pause', '-p', GetoptLong::NO_ARGUMENT],
        ['--remove', '-r', GetoptLong::NO_ARGUMENT]
    )
    begin
      opts.each do |opt, _|
        case opt
          when '--help'
            puts HELP_MESSAGE
            exit
          when '--remove'
            remove_mdbci_environment
           when '--pause'
            stop_mdbci_environment
          when '--start'
            prepare_mdbci_environment
          else
            raise PARSE_OPTIONS_AND_ARGS_ERROR
        end
      end
    end
  end

end

if File.identical?(__FILE__, $0)
  ParametrizedTestingEnvironmentSetup.new.parse_options_and_args
end

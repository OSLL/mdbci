# frozen_string_literal: true

require_relative 'base_command'
require_relative '../services/shell_commands'

# Command installs reqired dependencies for running mdbci
class SetupDependenciesCommand < BaseCommand
  include ShellCommands

  def self.synopsis
    'Installs vagrant and its dependencies'
  end

  def initialize(arg, env, logger)
    super(arg, env, logger)
    case get_linux_distro.downcase
    when 'centos'
      @dependency_manager = CentosDependencyManager.new(arg, env, logger)
    when 'debian', 'ubuntu'
      @dependency_manager = DebianDependencyManager.new(arg, env, logger)
    end
  end

  def execute
    if @env.reinstall
      return SUCCESS_RESULT unless delete_packages
    end
    result = @dependency_manager.install_dependencies
    result = prepare_environment if result.success?
    result.success? ? SUCCESS_RESULT : ERROR_RESULT
  end

  # Extracts linux distributor id from lsb_release command
  # @return [String] Linux distribution name
  def get_linux_distro
    lsb_distributor_regex = /^Distributor ID:\s*(\w+)$/
    lsb_output = run_command('lsb_release -a')
    lsb_output[:output].split('\n').each do |line|
      return line.match(lsb_distributor_regex)[1] if line =~ lsb_distributor_regex
    end
  end

  # Install vagrant plugins and prepares mdbci environment
  def prepare_environment
    result = run_command('vagrant plugin install vagrant-libvirt --plugin-version 0.0.43')
    result = run_command('vagrant plugin install vagrant-aws --plugin-version 0.7.2') if result[:value].success?
    result = run_command('sudo mkdir -p /var/lib/libvirt/libvirt-images') if result[:value].success?
    result = run_command('sudo virsh pool-create-as default dir '\
                         '--target /var/lib/libvirt/libvirt-images') if result[:value].success?
    result = run_command('sudo usermod -a -G libvirt $(whoami)') if result[:value].success?
    result = run_command('vagrant box add --force dummy '\
                         'https://github.com/mitchellh/vagrant-aws/raw/master/dummy.box') if result[:value].success?
    result[:value]
  end

  def delete_packages
    return unless ask_confirmation
    delete_libvirt_pool
    delete_vagrant_plugins
    @dependency_manager.delete_dependencies
    SUCCESS_RESULT
  end

  # Ask user to confirm clean installation
  def ask_confirmation
    $stdout.print("This operation will uninstall following packages:
      vagrant,
      libvirt-client,
      libvirt-dev,
    as well as all installed vagrant plugins and 'default' libvirt pool.
    Are you sure you want to continue? [y/N]: ")
    while input = gets.strip
      if input == 'y'
        return true
      elsif input == 'N'
        return false
      else
        $stdout.print('Please enter one of the options [y/N]: ')
      end
    end
  end

  def delete_libvirt_pool
    run_command('sudo virsh pool-destroy default')
    run_command('sudo virsh pool-delete default')
    run_command('sudo virsh pool-undefine default')
  end

  def delete_vagrant_plugins
    begin
      `vagrant -v`
    rescue
      $stdout.puts('Vagrant in not installed')
    else
      vagrant_plugin_list = run_command('vagrant plugin list')
      return if vagrant_plugin_list[:output] == 'No plugins installed.'
      plugins = vagrant_plugin_list[:output].split(/ \(.+\)\s+\- Version Constraint: [0-9.]+\n/)
      run_command("vagrant plugin uninstall #{plugins.join(' ')}")
    end
  end
end

# Base class for a dependency manager for a specific linux distribution
class DependencyManager
  include ShellCommands

  VAGRANT_VERSION = '2.2.0'
  VAGRANT_PACKAGE = "vagrant_#{VAGRANT_VERSION}_x86_64"
  VAGNRAT_URL = "https://releases.hashicorp.com/vagrant/#{VAGRANT_VERSION}/#{VAGRANT_PACKAGE}"

  def initialize(args, env, logger)
    @args = args
    @env = env
    @ui = logger
  end

  # Installs dependencies for supported platforms
  def install_dependencies
    raise 'Not implemented'
  end

  # Deletes dependencies on supported platform
  def delete_dependencies
    raise 'Not implemented'
  end
end

# Class that manages CentOS specific packages
class CentosDependencyManager < DependencyManager
  def install_dependencies
    result = run_command('sudo yum -y install libvirt-client qemu git')
    result = run_command("sudo yum -y install #{VAGNRAT_URL}.rpm") if result[:value].success?
    result[:value]
  end

  def delete_dependencies
    run_command('sudo yum -y remove vagrant')
    run_command('sudo yum -y remove libvirt-client')
  end
end

# Class that manages Debian specific packages, also suit for Ubuntu
class DebianDependencyManager < DependencyManager
  def install_dependencies
    run_command('sudo apt-get update')
    result = run_command('sudo apt-get -y install build-essential libxslt-dev '\
                         'libxml2-dev libvirt-dev wget git cmake')
    result = run_command("wget #{VAGNRAT_URL}.deb") if result[:value].success?
    result = run_command("sudo dpkg -i #{VAGRANT_PACKAGE}.deb") if result[:value].success?
    run_command("rm #{VAGRANT_PACKAGE}.deb")
    result[:value]
  end

  def delete_dependencies
    run_command('sudo dpkg -P vagrant')
    run_command('sudo dpkg -P libvirt-dev')
  end
end

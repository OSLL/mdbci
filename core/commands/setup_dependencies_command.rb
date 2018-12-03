# frozen_string_literal: true

require_relative 'base_command'
require_relative '../services/shell_commands'

# Command installs reqired dependencies for running mdbci
class SetupDependenciesCommand < BaseCommand
  include ShellCommands

  def self.synopsis
    'Install vagrant and its dependencies'
  end

  def show_help
    info = <<-HELP
'setup-dependencies' command prepares environment for starting virtual machines using MDBCI.

First it installs Vagrant and suited libvirt development library using native distribution package manager.

Then it installs 'vagrant-libvirt' and 'vagrant-aws' plugins for Vagrant.

After that 'default' VM pool created for libvirt and the current user added to the libvirt user group.

OPTIONS:
  --reinstall:
Delete previously installed dependencies and VM pools
    HELP
    @ui.info(info)
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
    if @env.show_help
      show_help
      return SUCCESS_RESULT
    end
    unless @dependency_manager
      @ui.error('Unsupported linux distribution.')
      @ui.error("Check 'mdbci setup-dependencies --help' for short manual installation instructions.")
      return ERROR_RESULT
    end
    if @env.reinstall
      return SUCCESS_RESULT unless delete_packages
    end
    install
  end

  private

  # Setups environment for mdbci
  #
  # @return [Integer] result of execution
  def install
    result = @dependency_manager.install_dependencies
    result = prepare_environment if result == SUCCESS_RESULT
    result = create_libvirt_pool if result == SUCCESS_RESULT
    result
  end

  # Extracts linux distributor id from lsb_release command
  # @return [String] Linux distribution name
  def get_linux_distro
    lsb_distributor_regex = /^ID=\W*(\w+)\W*$/
    lsb_output = run_command('cat /etc/os-release')
    lsb_output[:output].split('\n').each do |line|
      return line.match(lsb_distributor_regex)[1] if line =~ lsb_distributor_regex
    end
  end

  # Install vagrant plugins and prepares mdbci environment
  def prepare_environment
    run_sequence([
                   'vagrant plugin install vagrant-libvirt --plugin-version 0.0.43',
                   'vagrant plugin install vagrant-aws --plugin-version 0.7.2',
                   'sudo usermod -a -G libvirt $(whoami)',
                   'vagrant box add --force dummy https://github.com/mitchellh/vagrant-aws/raw/master/dummy.box'
                 ])[:value].exitstatus
  end

  # Created new libvirt pool with 'default' as name
  def create_libvirt_pool
    delete_libvirt_pool if run_command('sudo virsh pool-info default')[:value].success?
    images_dir = "#{ENV['HOME']}/libvirt-images"
    run_sequence([
                   "sudo mkdir -p #{images_dir}",
                   "sudo virsh pool-create-as default dir --target #{images_dir}"
                 ])[:value].exitstatus
  end

  # Deletes previously setup environment
  def delete_packages
    return unless ask_confirmation
    delete_libvirt_pool
    delete_vagrant_plugins
    @dependency_manager.delete_dependencies
  end

  # Ask user to confirm clean installation
  def ask_confirmation
    $stdout.print("This operation will uninstall following packages:
  vagrant,
  libvirt-client,
  libvirt-dev,
as well as all installed vagrant plugins and 'default' libvirt pool.
Are you sure you want to continue? [y/N]: ")
    while (input = gets.strip)
      return true if input == 'y'
      return false if input == 'N'
      $stdout.print('Please enter one of the options [y/N]: ')
    end
  end

  # Deletes 'defoult' libvirt pool
  def delete_libvirt_pool
    run_sequence([
                   'sudo virsh pool-destroy default',
                   'sudo virsh pool-delete default',
                   'sudo virsh pool-undefine default'
                 ], until_first_error: false)
  end

  # Deletes all vagrant plugins
  def delete_vagrant_plugins
    `vagrant -v`
  rescue Errno::ENOENT
    $stdout.puts('Vagrant in not installed')
  else
    vagrant_plugin_list = run_command('vagrant plugin list')
    return if vagrant_plugin_list[:output] =~ /No plugins installed/
    plugins = vagrant_plugin_list[:output].split(/ \(.+\)\s+\- Version Constraint: [0-9.]+\n/)
    run_command("vagrant plugin uninstall #{plugins.join(' ')}")
  end
end

# Base class for a dependency manager for a specific linux distribution
class DependencyManager
  include ShellCommands

  VAGRANT_VERSION = '2.2.1'
  VAGRANT_PACKAGE = "vagrant_#{VAGRANT_VERSION}_x86_64"
  VAGRANT_URL = "https://releases.hashicorp.com/vagrant/#{VAGRANT_VERSION}/#{VAGRANT_PACKAGE}"

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
    required_packages = ['libvirt-client', 'libvirt-devel', 'git']
    required_packages.each do |package|
      unless installed?(package)
        result = run_command("sudo yum install -y #{package}")[:value]
        return BaseCommand::ERROR_RESULT unless result.success?
      end
    end
    install_vagrant
  end

  # Installs or updates Vagrant if installed version older than VAGRANT_VERSION
  def install_vagrant
    if installed?('vagrant')
      vagrant_v = `vagrant -v`.match(/^Vagrant ([0-9.]+\s*)/)[1]
      return BaseCommand::SUCCESS_RESULT if vagrant_v >= VAGRANT_VERSION
    end
    run_command("sudo yum install -y #{VAGRANT_URL}.rpm")[:value].exitstatus
  end

  # Check if package is installed
  def installed?(package)
    run_command("yum list installed #{package}")[:value].success?
  end

  def delete_dependencies
    run_command('sudo yum -y remove vagrant libvirt-client libvirt-devel')[:value].exitstatus
  end
end

# Class that manages Debian specific packages, also suit for Ubuntu
class DebianDependencyManager < DependencyManager
  def install_dependencies
    run_command('sudo apt-get update')
    result = run_sequence([
                            'sudo apt-get -y install build-essential libxslt-dev '\
                            'libxml2-dev libvirt-dev wget git cmake',
                            "wget #{VAGRANT_URL}.deb",
                            "sudo dpkg -i #{VAGRANT_PACKAGE}.deb"
                          ])
    run_command("rm #{VAGRANT_PACKAGE}.deb")
    result[:value].exitstatus
  end

  def delete_dependencies
    run_sequence([
                   'sudo dpkg -P vagrant',
                   'sudo dpkg -P libvirt-dev'
                 ], until_first_error: false)
  end
end

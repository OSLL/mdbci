# frozen_string_literal: true

require_relative 'base_command'
require_relative '../services/shell_commands'

VAGRANT_VERSION = '2.2.3'
VAGRANT_LIBVIRT_PLUGIN_VERSION = '0.0.45'
VAGRANT_AWS_PLUGIN_VERSION = '0.7.2'

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
    case get_linux_distro
    when 'centos', 'rhel'
      @dependency_manager = CentosDependencyManager.new(arg, env, logger)
    when 'debian'
      @dependency_manager = DebianDependencyManager.new(arg, env, logger)
    when 'ubuntu'
      @dependency_manager = UbuntuDependencyManager.new(arg, env, logger)
    end
  end

  def execute
    if @env.show_help
      show_help
      return SUCCESS_RESULT
    end
    unless @dependency_manager
      @ui.error('Unsupported linux distribution.')
      @ui.error('Check Quickstart manual at https://github.com/mariadb-corporation/mdbci/blob/integration/docs/QUICKSTART.md')
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
    result = add_user_to_usergroup if result == SUCCESS_RESULT
    result = install_vagrant_plugins if result == SUCCESS_RESULT
    result = create_libvirt_pool if result == SUCCESS_RESULT
    export_libvirt_default_uri
    if result == SUCCESS_RESULT
      @ui.info('Dependencies successfully installed.')
      @ui.info('Please restart your computer in order to apply changes.')
    end
    result
  end

  # Extracts linux distributor id from lsb_release command
  # @return [String] Linux distribution name
  def get_linux_distro
    distribution_regex = /^ID=\W*(\w+)\W*/
    File.open('/etc/os-release') do |release_file|
      release_file.each do |line|
        return line.match(distribution_regex)[1].downcase if line =~ distribution_regex
      end
    end
  end

  # Adds user to libvirt user group
  def add_user_to_usergroup
    libvirt_groups = `getent group | grep libvirt | cut -d ":" -f1`.split("\n").join(',')
    if libvirt_groups.empty?
      @ui.error('Cannot add user to libvirt group. Libvirt group not found')
      return BaseCommand::ERROR_RESULT
    end
    run_command("sudo usermod -a -G #{libvirt_groups} $(whoami)")[:value].exitstatus
  end

  # Install vagrant plugins and prepares mdbci environment
  def install_vagrant_plugins
    install_libvirt_plugin = "vagrant plugin install vagrant-libvirt --plugin-version #{VAGRANT_LIBVIRT_PLUGIN_VERSION}"
    result = run_command(install_libvirt_plugin)[:value]
    unless result.success?
      @ui.error('Regular vagrant-libvirt installation failed. Retrying with additional options.')
      result = run_command("CONFIGURE_ARGS='with-ldflags=-L/opt/vagrant/embedded/lib "\
                           "with-libvirt-include=/usr/include/libvirt with-libvirt-lib=/usr/lib' "\
                           'GEM_HOME=~/.vagrant.d/gems GEM_PATH=$GEM_HOME:/opt/vagrant/embedded/gems '\
                           "PATH=/opt/vagrant/embedded/bin:$PATH #{install_libvirt_plugin}")[:value]
    end
    return result.exitstatus unless result.success?

    run_sequence([
                   "vagrant plugin install vagrant-aws --plugin-version #{VAGRANT_AWS_PLUGIN_VERSION}",
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

  # Adds LIBVIRT_DEFAULT_URI=qemu:///system environmental varible initialization
  # to the ~/.bashrc file of the current user
  def export_libvirt_default_uri
    export_line = 'export LIBVIRT_DEFAULT_URI=qemu:///system'
    File.open("#{ENV['HOME']}/.bashrc", 'a+') do |file|
      return SUCCESS_RESULT if file.find { |line| line.match(export_line) }

      file.puts(
        "\n# Generated by MDBCI",
        '# Use system bus as a default bus for the Libvirt communication',
        export_line
      )
    end
    @ui.info("Line '#{export_line}' added to your ~/.bashrc file.")
    SUCCESS_RESULT
  rescue Errno::EACCES
    @ui.error("Cannot write '#{export_line}' to ~/.bashrc.")
    @ui.error('Please add it manually in order to view VMs created by MDBCI.')
    ERROR_RESULT
  end
end

# Base class for a dependency manager for a specific linux distribution
class DependencyManager
  include ShellCommands

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

  # Check if required version of vagrant need to be installed
  def should_install_vagrant?
    vagrant_v_output = run_command('vagrant -v')[:output]
    installed_version = vagrant_v_output.match(/^Vagrant ([0-9.]+)\s*$/)[1]
    VAGRANT_VERSION > installed_version
  rescue Errno::ENOENT
    true
  end
end

# Class that manages CentOS specific packages
class CentosDependencyManager < DependencyManager
  def install_dependencies
    required_packages = [
      'ceph-common', 'qemu-kvm', 'gcc', 'libvirt', 'libvirt-client',
      'libvirt-devel', 'git', 'wget', 'rsync'
    ]
    required_packages.each do |package|
      unless installed?(package)
        result = run_command("sudo yum install -y #{package}")[:value]
        return BaseCommand::ERROR_RESULT unless result.success?
      end
    end
    return BaseCommand::ERROR_RESULT unless run_command('sudo systemctl start libvirtd')[:value].success?

    install_vagrant
  end

  def delete_dependencies
    run_command('sudo yum -y remove vagrant libvirt-client '\
                'libvirt-devel libvirt-daemon libvirt')[:value].exitstatus
  end

  # Installs or updates Vagrant if installed version older than VAGRANT_VERSION
  def install_vagrant
    return BaseCommand::SUCCESS_RESULT unless should_install_vagrant?

    result = run_sequence([
                            "wget #{VAGRANT_URL}.rpm",
                            "sudo yum install -y #{VAGRANT_PACKAGE}.rpm"
                          ])
    run_command("rm #{VAGRANT_PACKAGE}.rpm")
    result[:value].exitstatus
  end

  # Check if package is installed
  def installed?(package)
    run_command("yum list installed #{package}")[:value].success?
  end
end

# Class that manages Debian specific packages
class DebianDependencyManager < DependencyManager
  def install_dependencies
    run_command('sudo apt-get update')
    result = run_sequence([
                            'sudo DEBIAN_FRONTEND=noninteractive apt-get -yq install '\
                            'libvirt-daemon-system build-essential libxslt-dev '\
                            'libxml2-dev libvirt-dev wget git cmake curl rsync'
                          ])[:value]
    return result.exitstatus unless result.success?

    install_vagrant
  end

  def delete_dependencies
    run_command('sudo apt purge vagrant libvirt-dev')
  end

  def install_vagrant
    return BaseCommand::SUCCESS_RESULT unless should_install_vagrant?

    result = run_sequence([
                            "wget #{VAGRANT_URL}.deb",
                            "sudo dpkg -i #{VAGRANT_PACKAGE}.deb"
                          ])
    run_command("rm #{VAGRANT_PACKAGE}.deb")
    result[:value].exitstatus
  end
end

# Class that manages Ubuntu specific packages
class UbuntuDependencyManager < DebianDependencyManager
  def install_dependencies
    run_command('sudo apt-get update')
    result = run_sequence([
                            'sudo DEBIAN_FRONTEND=noninteractive apt-get -yq install libvirt-bin '\
                            'build-essential libxslt-dev libxml2-dev libvirt-dev wget git cmake rsync'
                          ])[:value]
    return result.exitstatus unless result.success?

    install_vagrant
  end
end

# frozen_string_literal: true

require_relative 'base_command'
require_relative '../services/shell_commands'

class SetupDependenciesCommand < BaseCommand
  include ShellCommands

  def self.synopsis
    'Installs vagrant and its dependencies'
  end

  def execute
    distro = get_linux_distro.downcase
    if @env.reinstall
      return SUCCESS_RESULT unless delete_dependencies(distro)
    end
    result = install_dependencies(distro)
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

  # Installs dependencies for supported platforms
  def install_dependencies(distro)
    vagrant_package = 'vagrant_2.2.0_x86_64'
    vagrant_url = "https://releases.hashicorp.com/vagrant/2.2.0/#{vagrant_package}"
    case distro
    when 'centos'
      result = run_command('sudo yum -y install libvirt-client qemu git')
      result = run_command("sudo yum -y install #{vagrant_url}.rpm") if result[:value].success?
    when 'debian', 'ubuntu'
      run_command('sudo apt-get update')
      result = run_command('sudo apt-get -y install build-essential libxslt-dev '\
                           'libxml2-dev libvirt-dev wget git cmake')
      result = run_command("wget #{vagrant_url}.deb") if result[:value].success?
      result = run_command("sudo dpkg -i #{vagrant_package}.deb") if result[:value].success?
      run_command("rm #{vagrant_package}.deb")
    else
      raise 'Unknown platform'
    end
    result[:value]
  end

  # Install vagrant plugins and prepares mdbci environment
  def prepare_environment
    result = run_command('vagrant plugin install vagrant-libvirt --plugin-version 0.0.43')
    result = run_command('vagrant plugin install vagrant-aws --plugin-version 0.7.2') if result[:value].success?
    result = run_command('sudo mkdir -p /var/lib/libvirt/libvirt-images')  if result[:value].success?
    result = run_command('sudo virsh pool-create-as default dir '\
                         '--target /var/lib/libvirt/libvirt-images') if result[:value].success?
    result = run_command('sudo usermod -a -G libvirt $(whoami)') if result[:value].success?
    result = run_command('vagrant box add --force dummy '\
                         'https://github.com/mitchellh/vagrant-aws/raw/master/dummy.box') if result[:value].success?
    result[:value]
  end

  def delete_dependencies(distro)
    $stdout.print("This operation will uninstall following packages:
  vagrant,
  #{distro == 'centos' ? 'libvirt-client' : 'libvirt-dev'},
as well as all installed vagrant plugins and 'default' libvirt pool.
Are you sure you want to continue? [y/N]: ")
    while input = gets.strip
      if input == 'y'
        break
      elsif input == 'N'
        return
      else
        $stdout.print('Please enter one of the options [y/N]: ')
      end
    end
    delete_libvirt_pool
    delete_vagrant_plugins
    delete_packages(distro)
    SUCCESS_RESULT
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

  def delete_packages(distro)
    case distro
    when 'centos'
      run_command('sudo yum -y remove vagrant')
      run_command('sudo yum -y remove libvirt-client')
    when 'debian', 'ubuntu'
      run_command('sudo dpkg -P vagrant')
      run_command('sudo dpkg -P libvirt-dev')
    end
  end
end

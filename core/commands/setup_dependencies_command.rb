# frozen_string_literal: true

require_relative 'base_command'
require_relative '../services/shell_commands'

class SetupDependenciesCommand < BaseCommand
  def self.synopsis
    'Installs vagrant and its dependencies'
  end

  def execute
    result = install_dependencies
    prepare_environment if result.success?
  end

  # Extracts linux distributor id from lsb_release command
  # @return [String] Linux distribution name
  def get_linux_distro
    lsb_distributor_regex = /^Distributor ID:\s*(\w+)$/
    lsb_output = ShellCommands.run_command($out, 'lsb_release -a')
    lsb_output[:output].split('\n').each do |line|
      return line.match(lsb_distributor_regex)[1] if line =~ lsb_distributor_regex
    end
  end

  # Installs dependencies for supported platforms
  def install_dependencies
    distro = get_linux_distro.downcase
    vagrant_package = 'vagrant_2.2.0_x86_64'
    vagrant_url = "https://releases.hashicorp.com/vagrant/2.2.0/#{vagrant_package}"
    case distro
    when 'centos'
      result = ShellCommands.run_command($out, 'sudo yum -y install libvirt-client qemu git')
      result = ShellCommands.run_command($out, "sudo yum -y install #{vagrant_url}.rpm") if result[:value].success?
    when 'debian', 'ubuntu'
      ShellCommands.run_command($out, 'sudo apt-get update')
      result = ShellCommands.run_command($out, 'sudo apt-get -y install build-essential libxslt-dev libxml2-dev libvirt-dev wget git cmake wget')
      result = ShellCommands.run_command($out, "wget #{vagrant_url}.deb") if result[:value].success?
      result = ShellCommands.run_command($out, "sudo dpkg -i #{vagrant_package}.deb") if result[:value].success?
      ShellCommands.run_command($out, "rm #{vagrant_package}.deb")
    else
      raise "Unknown platform"
    end
    result[:value]
  end

  # Install vagrant plugins and prepares mdbci environment
  def prepare_environment
    ShellCommands.run_command($out, 'vagrant plugin install vagrant-libvirt --plugin-version 0.0.43')
    ShellCommands.run_command($out, 'vagrant plugin install vagrant-aws --plugin-version 0.7.2')
    ShellCommands.run_command($out, 'sudo mkdir /var/lib/libvirt/libvirt-images')
    ShellCommands.run_command($out, 'sudo virsh pool-create default dir --target=/var/lib/libvirt/libvirt-images')
    ShellCommands.run_command($out, 'sudo usermod -a -G libvirt $(whoami)')
    ShellCommands.run_command($out, 'vagrant box add --force dummy https://github.com/mitchellh/vagrant-aws/raw/master/dummy.box')
    ShellCommands.run_command($out, 'mkdir mdbci')
    ShellCommands.run_command($out, 'cd mdbci')
    ShellCommands.run_command($out, 'wget http://max-tst-01.mariadb.com/ci-repository/mdbci')
    ShellCommands.run_command($out, 'chmod a+x mdbci')
  end
end

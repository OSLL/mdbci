# frozen_string_literal: true

require 'io/console'
require 'net/ssh'
require 'net/scp'

# Class allows to configure a specified machine using the chef-solo,
# MDBCI coockbooks and roles.
class MachineConfigurator
  def initialize(logger, root_path = File.expand_path('../../../chef-repository', __FILE__))
    @log = logger
    @root_path = root_path
  end

  # Run command on the remote machine and return result to the caller
  def run_command(machine, command)
    @log.info("Running command '#{command}' on the '#{machine['network']}' machine")
    within_ssh_session(machine) do |connection|
      ssh_exec(connection, command)
    end
  end

  # Upload chef scripts onto the machine and configure it using specified role. The method is able to transfer
  # extra files into the provision directory making runtime configuration of Chef scripts possible.
  # @param extra_files [Array<Array<String>>] pairs of source and target paths.
  def configure(machine, config_name, extra_files = [], sudo_password = '', chef_version = '13.8.0')
    @log.info("Configuring machine #{machine['network']} with #{config_name}")
    within_ssh_session(machine) do |connection|
      install_chef_on_server(connection, sudo_password, chef_version)
      remote_dir = '/tmp/provision'
      copy_chef_files(connection, remote_dir, sudo_password, extra_files)
      run_chef_solo(config_name, connection, remote_dir, sudo_password)
      sudo_exec(connection, sudo_password, "rm -rf #{remote_dir}")
    end
  end

  # Connect to the specified machine and yield active connection
  # @param machine [Hash] information about machine to connect
  def within_ssh_session(machine)
    options = Net::SSH.configuration_for(machine['network'], true)
    options[:keys] = [machine['keyfile']]
    Net::SSH.start(machine['network'], machine['whoami'], options) do |ssh|
      yield ssh
    end
  end

  # rubocop:disable Metrics/MethodLength
  def sudo_exec(connection, sudo_password, command)
    @log.info("Running 'sudo -S #{command}' on the remote server.")
    output = ''
    connection.open_channel do |channel, _success|
      channel.on_data do |_, data|
        data.split("\n").map(&:chomp)
            .select { |line| line =~ /\p{Graph}+$/ }
            .each { |line| @log.debug("ssh: #{line}") }
        output += "#{data}\n"
      end
      channel.on_extended_data do |ch, _, data|
        if data =~ /^\[sudo\] password for /
          @log.debug('ssh: providing sudo password')
          ch.send_data "#{sudo_password}\n"
        else
          @log.debug("ssh error: #{data}")
        end
      end
      channel.exec("sudo -S #{command}")
      channel.wait
    end.wait
    output
  end
  # rubocop:enable Metrics/MethodLength

  # rubocop:disable Metrics/MethodLength
  def ssh_exec(connection, command)
    @log.info("Running '#{command}' on the remote server")
    output = ''
    connection.open_channel do |channel, _success|
      channel.on_data do |_, data|
        data.split("\n").map(&:chomp)
            .select { |line| line =~ /\p{Graph}+/ }
            .each { |line| @log.debug("ssh: #{line}") }
        output += "#{data}\n"
      end
      channel.on_extended_data do |_, _, data|
        @log.debug("ssh error: #{data}")
      end
      channel.exec(command)
      channel.wait
    end.wait
    output
  end
  # rubocop:enable Metrics/MethodLength

  # Upload specified file to the remote location on the server
  # @param connection [Connection] ssh connection to use
  # @param source [String] path to the file on the local machine
  # @param target [String] path to the file on the remote machine
  # @param recursive [Boolean] use recursive copying or not
  def upload_file(connection, source, target, recursive = true)
    connection.scp.upload!(source, target, recursive: recursive)
  end

  private

  def install_chef_on_server(connection, sudo_password, chef_version)
    @log.info("Installing Chef #{chef_version} on the server.")
    output = ssh_exec(connection, 'chef-solo --version')
    if output.include?(chef_version)
      @log.info("Chef #{chef_version} is already installed on the server.")
      return
    end
    ssh_exec(connection, 'curl -s -L https://www.chef.io/chef/install.sh --output install.sh')
    sudo_exec(connection, sudo_password, "bash install.sh -v #{chef_version}")
    ssh_exec(connection, 'rm install.sh')
  end

  def copy_chef_files(connection, remote_dir, sudo_password, extra_files)
    @log.info('Copying chef files to the server.')
    sudo_exec(connection, sudo_password, "rm -rf #{remote_dir}")
    ssh_exec(connection, "mkdir -p #{remote_dir}")
    %w[configs vendor-cookbooks roles solo.rb]
      .map { |name| ["#{@root_path}/#{name}", name] }
      .select { |path, _| File.exist?(path) }
      .concat(extra_files)
      .each do |source, target|
      upload_file(connection, source, "#{remote_dir}/#{target}")
    end
  end

  def run_chef_solo(config_name, connection, remote_dir, sudo_password)
    sudo_exec(connection, sudo_password, "chef-solo -c #{remote_dir}/solo.rb -j #{remote_dir}/configs/#{config_name}")
  end
end

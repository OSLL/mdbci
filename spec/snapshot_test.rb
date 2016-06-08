require 'rspec'
require 'fileutils'
require 'open3'

require_relative 'spec_helper'
require_relative '../core/snapshot'

PROVIDERS = %w(libvirt docker virtualbox)

PATH_TO_TEMPLATES = 'spec/test_machine_configurations'
CONFIG_PREFIX = 'snapshot_test'

VAGRANT_DESTROY_FORCE = 'vagrant destroy -f'
TEST_INFO_TAG = 'TEST_INFO:'
TEST_ERROR_TAG = 'TEST_ERROR:'

TEMPLATE_COOKBOOK_PATH = 'cookbook_path'
TEMPLATE_AWS_CONFIG = 'aws_config'

CANNOT_GENERATE_CONFIG_ERROR = 'can not generate configuration'
CANNOT_START_MACHINE_ERROR = 'can start machine'
NODES_NOT_FOUND_ERROR = 'nodes are not found'

def docker_list_output_initial(node_box, provider)
  return <<EOF
#{node_box}
mdbci_snapshot_snapshot_test_initial_#{provider}
EOF
end

def docker_list_output_with_mariadb(node_box, provider)
  return <<EOF
#{node_box}
mdbci_snapshot_snapshot_test_initial_#{provider}
mdbci_snapshot_snapshot_test_#{provider}
EOF
end

def standard_list_output_initial(provider)
  return <<EOF
mdbci_snapshot_snapshot_test_initial_#{provider}
EOF
end

def standard_list_output_with_mariadb(provider)
  return <<EOF
mdbci_snapshot_snapshot_test_initial_#{provider}
mdbci_snapshot_snapshot_test_#{provider}
EOF
end

def execute_bash(cmd)
  puts "#{TEST_INFO_TAG} executing #{cmd}"
  exit_code = Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thr|
    stdin.close
    stdout.each { |line| puts "#{TEST_INFO_TAG} #{line}" }
    stdout.close
    stderr.each { |line| puts "#{TEST_ERROR_TAG} #{line}" }
    stderr.close
    wait_thr.value.exitstatus
  end
  puts "RETEUEN CODE = #{exit_code}"
  return exit_code
end

def find_nodes(destination)
  nodes = Array.new
  template = JSON.parse(File.read(File.read("#{destination}/template")))
  template.each do |possible_node|
    if possible_node[0] != TEMPLATE_AWS_CONFIG and possible_node[0] != TEMPLATE_COOKBOOK_PATH
      nodes.push possible_node[0]
    end
  end
  raise NODES_NOT_FOUND_ERROR if nodes.empty?
  return nodes
end

def cmd_generate(provider, destination)
  return "./mdbci --template #{PATH_TO_TEMPLATES}/#{CONFIG_PREFIX}_#{provider}.json generate #{destination}"
end

def cmd_up(destination)
  return "./mdbci up #{destination}"
end

def cmd_run_command(command, destination, node_name)
  return "./mdbci sudo --command #{command} #{destination}/#{node_name}"
end

def cmd_setup_product_repo(product, product_version, destination, node_name)
  return "./mdbci setup_repo --product #{product} --product-version #{product_version} #{destination}/#{node_name}"
end

def cmd_install_product(product, destination, node_name)
  return "./mdbci install_product --product #{product} #{destination}/#{node_name}"
end

def cmd_snapshot_list(destination, node_name)
  return "./mdbci snapshot --silent list --path-to-nodes #{destination} --node-name #{node_name}"
end

def cmd_snapshot_take(destination, node_name, snapshot_name)
  return "./mdbci snapshot take --path-to-nodes #{destination} --node-name #{node_name} --snapshot-name #{snapshot_name}"
end

def cmd_snapshot_revert(destination, node_name, snapshot_name)
  return "./mdbci snapshot revert --path-to-nodes #{destination} --node-name #{node_name} --snapshot-name #{snapshot_name}"
end

def cmd_snapshot_remove(destination, node_name, snapshot_name)
  return "./mdbci snapshot remove --path-to-nodes #{destination} --node-name #{node_name} --snapshot-name #{snapshot_name}"
end

def start_machines(destination)
  if execute_bash(cmd_up(destination)) != 0
    puts "#{TEST_ERROR_TAG} removing failed configurations (to avoid mess)"
    remove_config_and_machines(destination)
    raise "#{TEST_ERROR_TAG} #{CANNOT_START_MACHINE_ERROR} #{destination}"
  end
end

def remove_config_and_machines(destination)
  if Dir.exists? destination
    current_dir = Dir.pwd
    Dir.chdir destination
    execute_bash VAGRANT_DESTROY_FORCE
    Dir.chdir current_dir
    FileUtils.rm_rf destination
  end
end

def clear_network_configurations
  # Clear libvirt networks
  puts "#{TEST_INFO_TAG } removing libvirt networks..."
  libvirt_networks = `virsh -q net-list | awk '{print $1}'`
  libvirt_networks.each_line do |network|
    if network != 'default'
      execute_bash "virsh net-destroy #{network}"
    end
  end
  # Clear virtualbox networks
  puts "#{TEST_INFO_TAG } removing virtualbox networks..."
  virtualbox_networks = `VBoxManage list hostonlyifs | grep ^Name: | awk '{print $2}'`
  virtualbox_networks.each_line do |network|
    if network != 'default'
      execute_bash "VBoxManage hostonlyif remove #{network}"
    end
  end
end

describe 'Run preparation' do
  PROVIDERS.each do |provider|
    destination = "#{CONFIG_PREFIX}_#{provider}"
    puts "#{TEST_INFO_TAG } removing old generated configuration: #{destination}"
    remove_config_and_machines(destination)
    puts "#{TEST_INFO_TAG } generating"
    raise "#{TEST_ERROR_TAG } #{CANNOT_GENERATE_CONFIG_ERROR} #{destination}" if execute_bash(cmd_generate(provider, destination)) != 0
  end
end


PROVIDERS.each do |provider|
  describe "Snapshot test for provider: #{provider}" do

    destination = "#{CONFIG_PREFIX}_#{provider}"

    before :all do
      clear_network_configurations
      start_machines destination
    end
    after :all do
      remove_config_and_machines destination
    end

    # Each node testing
    find_nodes(destination).each do |node_name|

      node_box = `./mdbci show box #{destination}/#{node_name} --silent`.delete "\n"

      it "creating initial snapshot in #{destination} for #{node_name}" do
        execute_bash(cmd_snapshot_take(destination, node_name, "snapshot_test_initial_#{provider}")).should eql 0
      end

      it 'checking that snapshot was created' do
        # For docker we need to get first image (first snapshot) to check right output
        # because docker has snapshot when it's created (docker snapshot == docker image)
        if provider == 'docker'
          `#{cmd_snapshot_list(destination, node_name)}`.should eql docker_list_output_initial(node_box, provider)
        else
          `#{cmd_snapshot_list(destination, node_name)}`.should eql standard_list_output_initial(provider)
        end
      end

      it 'installing mariadb 5.5 on initial machine and checking it' do
        execute_bash(cmd_setup_product_repo('mariadb', '5.5', destination, node_name))
        execute_bash(cmd_install_product('mariadb', destination, node_name))
        execute_bash(cmd_run_command('"mysql -V | grep 5.5"', destination, node_name)).should eql 0
      end

      it "creating snapshot with mariadb 5.5 installed in #{destination} for #{node_name}" do
        execute_bash(cmd_snapshot_take(destination, node_name, "snapshot_test_#{provider}")).should eql 0
      end

      it 'checking that snapshot was created' do
        # For docker we need to get first image (first snapshot) to check right output
        # because docker has snapshot when it's created (docker snapshot == docker image)
        if provider == 'docker'
          `#{cmd_snapshot_list(destination, node_name)}`.should eql docker_list_output_with_mariadb(node_box, provider)
        else
          `#{cmd_snapshot_list(destination, node_name)}`.should eql standard_list_output_with_mariadb(provider)
        end
      end

      it 'reverting snapshots (to initial machine)' do
        execute_bash(cmd_snapshot_revert(destination, node_name, "mdbci_snapshot_snapshot_test_initial_#{provider}")).should eql 0
      end

      it 'checking that mariadb is not installed on reverted machine' do
        execute_bash(cmd_run_command('"mysql -V"', destination, node_name)).should_not eql 0
      end

      it 'installing mariadb 10.0 on initial machine and checking it' do
        execute_bash(cmd_setup_product_repo('mariadb', '10.0', destination, node_name))
        execute_bash(cmd_install_product('mariadb', destination, node_name))
        execute_bash(cmd_run_command('"mysql -V | grep 10.0"', destination, node_name)).should eql 0
      end

      it 'reverting snapshots to state with mariadb 5.5 installed' do
        execute_bash(cmd_snapshot_revert(destination, node_name, "mdbci_snapshot_snapshot_test_#{provider}")).should eql 0
      end

      it 'checking that on reverted machine mariadb has version 5.5' do
        execute_bash(cmd_run_command('"mysql -V | grep 5.5"', destination, node_name)).should eql 0
      end

      # Removing initial snapshot
      it 'removing initial snapshot' do
        execute_bash(cmd_snapshot_remove(destination, node_name, "mdbci_snapshot_snapshot_test_initial_#{provider}")).should eql 0
      end

      # Removing last snapshot
      if provider != 'docker'
        it 'removing snapshot with mariadb 5.5' do
          execute_bash(cmd_snapshot_remove(destination, node_name, "mdbci_snapshot_snapshot_test_#{provider}")).should eql 0
        end
      else
        # Docker now using last snapshot (image) with running machine and could not be deleted
        it "trying to remove initial docker snapshot, but it's not going to happened (because snapshot is in use)" do
          execute_bash(cmd_snapshot_remove(destination, node_name, "mdbci_snapshot_snapshot_test_#{provider}")).should_not eql 0
        end
        # So docker has after all 2 we have snapshots: first - is one that was created with 'mdbci up' and
        # other one that we created manually, so we can't delete snapshot that we created manually
        # so we will rollback docker machine to very first snapshot and after that delete last snapshot
        it 'reverting docker machine to very first snapshot' do
          execute_bash(cmd_snapshot_revert(destination, node_name, node_box)).should eql 0
        end
        # now we can delete last snapshot
        it 'removing last docker snapshot' do
          execute_bash(cmd_snapshot_remove(destination, node_name, "mdbci_snapshot_snapshot_test_#{provider}")).should eql 0
        end
      end

    end
  end
end

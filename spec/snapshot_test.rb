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

def execute_bash(cmd)
  puts "#{TEST_INFO_TAG} executing #{cmd}"
  return Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thr|
    stdin.close
    stdout.each { |line| puts "#{TEST_INFO_TAG} #{line}" }
    stdout.close
    stderr.each { |line| puts "#{TEST_ERROR_TAG} #{line}" }
    stderr.close
    wait_thr.value.exitstatus
  end
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

def cmd_snapshot_list(destination)
  return "./mdbci snapshot --silent list --path-to-nodes #{destination}"
end

def cmd_snapshot_take(destination, node_name, snapshot_name)
  return "./mdbci snapshot take --path-to-nodes #{destination} --node-name #{node_name} --snapshot-name #{snapshot_name}"
end

def cmd_snapshot_take_all(destination)
  return "./mdbci snapshot take --path-to-nodes #{destination}"
end

def cmd_snapshot_remove(destination, node_name, snapshot_name)
  return "./mdbci snapshot remove --path-to-nodes #{destination} --node-name #{node_name} --snapshot-name #{snapshot_name}"
end

def cmd_snapshot_remove_all(destination)
  return "./mdbci snapshot remove --path-to-nodes #{destination}"
end

def cmd_snapshot_revert(destination, node_name, snapshot_name)
  return "./mdbci snapshot revert --path-to-nodes #{destination} --node-name #{node_name} --snapshot-name #{snapshot_name}"
end

def cmd_snapshot_revert_all(destination)
  return "./mdbci snapshot revert --path-to-nodes #{destination}"
end

def cmd_setup_product_repo(product, product_version, destination, node_name)
  return "./mdbci setup_repo --product #{product} --product-version #{product_version} #{destination}/#{node_name}"
end

def cmd_install_product(product, destination, node_name)
  return "./mdbci install_product --product #{product} #{destination}/#{node_name}"

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
  describe 'Snapshot test for provider:' do
    destination = "#{CONFIG_PREFIX}_#{provider}"

    before :all do
      clear_network_configurations
      start_machines destination
    end

    after :all do
      remove_config_and_machines destination
    end

    # Each node testing
    it "#{provider}" do
      find_nodes(destination).each do |node_name|

        # Box will be needed to work with docker (as it's the very first snapshot name)
        node_box = `./mdbci show box #{destination}/#{node_name} --silent`

        it "creating snapshots for provider #{provider} in #{destination} for each node" do
          execute_bash(cmd_snapshot_take(destination, node_name, "snapshot_test_#{provider}")).should eql? 0
        end

        it 'checking that snapshot was created' do
          # For docker we need to get first image (first snapshot) to check right output
          # because docker has snapshot when it's created (docker snapshot == docker image)
          output = provider == 'docker' ? "#{node_box}\nsnapshot_test_#{provider}" : "snapshot_test_#{provider}"
          `#{cmd_snapshot_list(destination)}`.should eql? output
        end

        it 'checking that on initial machine mariadb is not installed' do
          execute_bash(cmd_run_command('"mysql -V"', destination, node_name)).should_not eql? 0
        end

        it 'checking mariadb source list on initial machine is not installed' do
          execute_bash(cmd_run_command('"cat /etc/apt/"', destination, node_name)).should_not eql? 0
        end

        execute_bash(cmd_setup_product_repo('mariadb', '10.0', destination, node_name))
        execute_bash(cmd_install_product('mariadb', destination, node_name))

        it 'checking that in initial machine mariadb is installed (after installation)' do
          execute_bash(cmd_run_command('"mysql -V"', destination, node_name)).should eql? 0
        end

        it 'checking mariadb source list in initial machine is installed (after installation)' do
          execute_bash(cmd_run_command('"cat /etc/apt/"', destination, node_name)).should eql? 0
        end

        it 'reverting snapshots (to initial machine)' do
          execute_bash(cmd_snapshot_revert(destination, node_name, "snapshot_test_#{provider}")).should eql? 0
        end

        it 'checking that in initial machine mariadb is not installed (after reverting to initial machine)' do
          execute_bash(cmd_run_command('"mysql -V"', destination, node_name)).should_not eql? 0
        end

        it 'checking mariadb source list in initial machine is not installed (after reverting to initial machine)' do
          execute_bash(cmd_run_command('"cat /etc/apt/"', destination, node_name)).should_not eql? 0
        end

        # Removing newly created snapshot
        if provider != 'docker'
          execute_bash(cmd_snapshot_remove(destination, node_name, "snapshot_test_#{provider}")).should eql? 0
        else
          # Docker now using last snapshot (image) with running machine and could not be deleted
          it "trying to remove snapshot, but it's not going to happened (because snapshot is in use)" do
            execute_bash(cmd_snapshot_remove(destination, node_name, "snapshot_test_#{provider}")).should_not eql? 0
          end
          # So docker has after all 2 we have snapshots: first - is one that was created with 'mdbci up' and
          # other one that we created manually, so we can't delete snapshot that we created manually
          # so we will rollback docker machine to very first snapshot and after that delete last snapshot
          it 'rolling back docker machine to very first snapshot' do
            execute_bash(cmd_snapshot_revert(destination, node_name, node_box)).should eql? 0
          end
          # now we can delete last snapshot
          it "removing last docker snapshot" do
            execute_bash(cmd_snapshot_remove(destination, node_name, "snapshot_test_#{provider}")).should_not eql? 0
          end
          execute_bash(cmd_snapshot_remove(destination, node_name, "snapshot_test_#{provider}")).should eql? 0
        end
      end
    end

    # Bunch of nodes testing
    it "#{provider}" do
      it 'creating snaphsots for each provider and each node' do
        execute_bash(cmd_snapshot_take_all(destination)).should eql? 0
      end
      find_nodes(destination).each do |node_name|
        it 'checking that snapshot was created' do
          output = provider == 'docker' ? "ubuntu_trusty_docker\nsnapshot_test_#{provider}" : "snapshot_test_#{provider}"
          `#{cmd_snapshot_list(destination)}`.should eql? output
        end
        it 'checking that on initial machine mariadb is not installed' do
          execute_bash(cmd_run_command('"mysql -V"', destination, node_name)).should_not eql? 0
        end

        it 'checking mariadb source list on initial machine is not installed' do
          execute_bash(cmd_run_command('"cat /etc/apt/"', destination, node_name)).should_not eql? 0
        end

        execute_bash(cmd_setup_product_repo('mariadb', '10.0', destination, node_name))
        execute_bash(cmd_install_product('mariadb', destination, node_name))

        it 'checking that in initial machine mariadb is installed (after installation)' do
          execute_bash(cmd_run_command('"mysql -V"', destination, node_name)).should eql? 0
        end

        it 'checking mariadb source list in initial machine is installed (after installation)' do
          execute_bash(cmd_run_command('"cat /etc/apt/"', destination, node_name)).should eql? 0
        end

      end
      it 'reverting snapshots' do
        execute_bash(cmd_snapshot_revert_all(destination)).should eql? 0
      end
      find_nodes(destination).each do |node_name|
        it 'checking that in initial machine mariadb is not installed (after reverting to initial machine)' do
          execute_bash(cmd_run_command('"mysql -V"', destination, node_name)).should_not eql? 0
        end

        it 'checking mariadb source list in initial machine is not installed (after reverting to initial machine)' do
          execute_bash(cmd_run_command('"cat /etc/apt/"', destination, node_name)).should_not eql? 0
        end
      end
    end
  end
end

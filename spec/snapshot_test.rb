require 'rspec'
require 'fileutils'
require 'open3'

require_relative 'spec_helper'

PATH_TO_TEMPLATES = 'spec/test_machine_configurations'
CONFIG_PREFIX = 'snapshot_test'
DESTINATIONS = %W(#{CONFIG_PREFIX}_libvirt #{CONFIG_PREFIX}_docker #{CONFIG_PREFIX}_virtualbox)
NODES_NAMES = %W{node0}
SNAPSHOTS_NAMES = {
    DESTINATIONS[0] => {
        :initial => "#{DESTINATIONS[0]}_initial",
        :initial_mariadb => "#{DESTINATIONS[0]}_initial_mariadb"
    },
    DESTINATIONS[1] => {
        :initial => "#{DESTINATIONS[1]}_initial",
        :initial_mariadb => "#{DESTINATIONS[1]}_initial_mariadb"
    },
    DESTINATIONS[2] => {
        :initial => "#{DESTINATIONS[2]}_initial",
        :initial_mariadb => "#{DESTINATIONS[2]}_initial_mariadb"
    }
}
DOCKER_SNAPSHOT_LIST_INITIAL = <<EOF
ubuntu_trusty_docker
mdbci_snapshot_snapshot_test_docker_initial_snapshot_test_docker_node0
EOF
DOCKER_SNAPSHOT_LIST_INITIAL_MARIADB = <<EOF
ubuntu_trusty_docker
mdbci_snapshot_snapshot_test_docker_initial_snapshot_test_docker_node0
mdbci_snapshot_snapshot_test_docker_initial_mariadb_snapshot_test_docker_node0
EOF
LIBVIRT_SNAPSHOT_LIST_INITIAL = <<EOF
mdbci_snapshot_snapshot_test_libvirt_initial_snapshot_test_libvirt_node0
EOF
LIBVIRT_SNAPSHOT_LIST_INITIAL_MARIADB = <<EOF
mdbci_snapshot_snapshot_test_libvirt_initial_snapshot_test_libvirt_node0
mdbci_snapshot_snapshot_test_libvirt_initial_mariadb_snapshot_test_libvirt_node0
EOF
VIRTUALBOX_SNAPSHOT_LIST_INITIAL = <<EOF
mdbci_snapshot_snapshot_test_virtualbox_initial_snapshot_test_virtualbox_node0
EOF
VIRTUALBOX_SNAPSHOT_LIST_INITIAL_MARIADB = <<EOF
mdbci_snapshot_snapshot_test_virtualbox_initial_snapshot_test_virtualbox_node0
mdbci_snapshot_snapshot_test_virtualbox_initial_mariadb_snapshot_test_virtualbox_node0
EOF
SNAPSHOT_LIST_OUTPUT = {
    DESTINATIONS[0] => {
        :initial => LIBVIRT_SNAPSHOT_LIST_INITIAL,
        :initial_mariadb => LIBVIRT_SNAPSHOT_LIST_INITIAL_MARIADB
    },
    DESTINATIONS[1] => {
        :initial => DOCKER_SNAPSHOT_LIST_INITIAL,
        :initial_mariadb => DOCKER_SNAPSHOT_LIST_INITIAL_MARIADB
    },
    DESTINATIONS[2] => {
        :initial => VIRTUALBOX_SNAPSHOT_LIST_INITIAL,
        :initial_mariadb => VIRTUALBOX_SNAPSHOT_LIST_INITIAL_MARIADB
    }
}

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
  exit_code = Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thr|
    stdin.close
    stdout.each { |line| puts "#{TEST_INFO_TAG} #{line}" }
    stdout.close
    stderr.each { |line| puts "#{TEST_ERROR_TAG} #{line}" }
    stderr.close
    wait_thr.value.exitstatus
  end
  puts "#{TEST_INFO_TAG} RETURN CODE = #{exit_code}"
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

def cmd_generate(destination)
  return "./mdbci --template #{PATH_TO_TEMPLATES}/#{destination}.json generate #{destination}"
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

def cmd_snapshots_take(destination, snapshot_name)
  return "./mdbci snapshot take --path-to-nodes #{destination} --snapshot-name #{snapshot_name}"
end

def cmd_snapshot_revert(destination, node_name, snapshot_name)
  return "./mdbci snapshot revert --path-to-nodes #{destination} --node-name #{node_name} --snapshot-name #{snapshot_name}"
end

def cmd_snapshots_revert(destination, snapshot_name)
  return "./mdbci snapshot revert --path-to-nodes #{destination} --snapshot-name #{snapshot_name}"
end

def cmd_snapshot_remove(destination, node_name, snapshot_name)
  return "./mdbci snapshot remove --path-to-nodes #{destination} --node-name #{node_name} --snapshot-name #{snapshot_name}"
end

def generate_machines(destination)
  if execute_bash(cmd_generate(destination)) != 0
    raise "#{TEST_ERROR_TAG} #{CANNOT_GENERATE_CONFIG_ERROR} #{destination}"
  end
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
  execute_bash('docker rmi mdbci_snapshot_snapshot_test_docker_initial_snapshot_test_docker_node0')
  execute_bash('docker rmi mdbci_snapshot_snapshot_test_docker_initial_mariadb_snapshot_test_docker_node0')
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

DESTINATIONS.each do |destination|

  next if destination == DESTINATIONS[2]

  describe "Individual nodes snapshot test in destination: #{destination}" do

    before :all do
      remove_config_and_machines destination
      clear_network_configurations
      generate_machines destination
      start_machines destination
    end

    after :all do
      remove_config_and_machines destination
    end

    NODES_NAMES.each do |node_name|

      it "creating initial snapshot in #{destination} for #{node_name}" do
        execute_bash(cmd_snapshot_take(destination, node_name, SNAPSHOTS_NAMES[destination][:initial])).should eql 0
      end

      it 'checking that snapshot was created' do
        `#{cmd_snapshot_list(destination, node_name)}`.should eql SNAPSHOT_LIST_OUTPUT[destination][:initial]
      end

      it 'installing mariadb 5.5 on initial machine and checking it' do
        execute_bash(cmd_setup_product_repo('mariadb', '5.5', destination, node_name))
        execute_bash(cmd_install_product('mariadb', destination, node_name))
        execute_bash(cmd_run_command('"mysql -V | grep 5.5"', destination, node_name)).should eql 0
      end

      it "creating snapshot with mariadb 5.5 installed in #{destination} for #{node_name}" do
        execute_bash(cmd_snapshot_take(destination, node_name, SNAPSHOTS_NAMES[destination][:initial_mariadb])).should eql 0
      end

      it 'checking that snapshot was created' do
        `#{cmd_snapshot_list(destination, node_name)}`.should eql SNAPSHOT_LIST_OUTPUT[destination][:initial_mariadb]
      end

      it "reverting #{node_name} to initial snapshot" do
        execute_bash(cmd_snapshot_revert(destination, node_name, SNAPSHOTS_NAMES[destination][:initial])).should eql 0
      end

      it 'checking that mariadb is not installed on reverted machine' do
        execute_bash(cmd_run_command('"mysql -V"', destination, node_name)).should_not eql 0
      end

      it 'installing mariadb 10.0 on initial machine and checking it' do
        execute_bash(cmd_setup_product_repo('mariadb', '10.0', destination, node_name))
        execute_bash(cmd_install_product('mariadb', destination, node_name))
        execute_bash(cmd_run_command('"mysql -V | grep 10.0"', destination, node_name)).should eql 0
      end

      it "reverting #{node_name} to snapshot with mariadb 5.5 installed" do
        execute_bash(cmd_snapshot_revert(destination, node_name, SNAPSHOTS_NAMES[destination][:initial_mariadb])).should eql 0
      end

      it 'checking that on reverted machine mariadb has version 5.5' do
        execute_bash(cmd_run_command('"mysql -V | grep 5.5"', destination, node_name)).should eql 0
      end

      # Removing initial snapshot
      it 'removing initial snapshot' do
        execute_bash(cmd_snapshot_remove(destination, node_name, SNAPSHOTS_NAMES[destination][:initial])).should eql 0
      end

      # Removing last snapshot
      if destination != DESTINATIONS[1] # DESTINATION[1] = snapshot_test_docker
        it 'removing snapshot with mariadb 5.5' do
          execute_bash(cmd_snapshot_remove(destination, node_name, SNAPSHOTS_NAMES[destination][:initial_mariadb])).should eql 0
        end
      else
        # Docker now using last snapshot (image) with running machine and could not be deleted
        it "trying to remove last docker snapshot, but it's not going to happened (because snapshot is in use)" do
          execute_bash(cmd_snapshot_remove(destination, node_name, SNAPSHOTS_NAMES[destination][:initial_mariadb])).should_not eql 0
        end

      end

    end

  end

end

DESTINATIONS.each do |destination|

  next if destination == DESTINATIONS[2]

  describe "Buch of nodes snapshot test in destination: #{destination}" do

    before :all do
      remove_config_and_machines destination
      clear_network_configurations
      generate_machines destination
      start_machines destination
    end

    after :all do
      remove_config_and_machines destination
    end

    it "creating initial snapshots in #{destination} for all nodes" do
      execute_bash(cmd_snapshots_take(destination, SNAPSHOTS_NAMES[destination][:initial])).should eql 0
    end

    NODES_NAMES.each do |node_name|

      it 'checking that snapshot was created' do
        `#{cmd_snapshot_list(destination, node_name)}`.should eql SNAPSHOT_LIST_OUTPUT[destination][:initial]
      end

      it 'installing mariadb 5.5 on initial machine and checking it' do
        execute_bash(cmd_setup_product_repo('mariadb', '5.5', destination, node_name))
        execute_bash(cmd_install_product('mariadb', destination, node_name))
        execute_bash(cmd_run_command('"mysql -V | grep 5.5"', destination, node_name)).should eql 0
      end

    end

    it "creating snapshot with mariadb 5.5 installed in #{destination} for all nodes" do
      execute_bash(cmd_snapshots_take(destination, SNAPSHOTS_NAMES[destination][:initial_mariadb])).should eql 0
    end

    NODES_NAMES.each do |node_name|

      it 'checking that snapshot was created' do
        `#{cmd_snapshot_list(destination, node_name)}`.should eql SNAPSHOT_LIST_OUTPUT[destination][:initial_mariadb]
      end

    end

    it 'reverting all nodes to initial snapshots' do
      execute_bash(cmd_snapshots_revert(destination, SNAPSHOTS_NAMES[destination][:initial])).should eql 0
    end

    NODES_NAMES.each do |node_name|

      it 'checking that mariadb is not installed on reverted machine' do
        execute_bash(cmd_run_command('"mysql -V"', destination, node_name)).should_not eql 0
      end

      it 'installing mariadb 10.0 on initial machine and checking it' do
        execute_bash(cmd_setup_product_repo('mariadb', '10.0', destination, node_name))
        execute_bash(cmd_install_product('mariadb', destination, node_name))
        execute_bash(cmd_run_command('"mysql -V | grep 10.0"', destination, node_name)).should eql 0
      end

    end

    it 'reverting nodes to snapshot with mariadb 5.5 installed' do
      execute_bash(cmd_snapshots_revert(destination, SNAPSHOTS_NAMES[destination][:initial_mariadb])).should eql 0
    end

    NODES_NAMES.each do |node_name|

      it 'checking that on reverted machine mariadb has version 5.5' do
        execute_bash(cmd_run_command('"mysql -V | grep 5.5"', destination, node_name)).should eql 0
      end

      # Removing initial snapshot
      it 'removing initial snapshot' do
        execute_bash(cmd_snapshot_remove(destination, node_name, SNAPSHOTS_NAMES[destination][:initial])).should eql 0
      end

      # Removing last snapshot
      if destination != DESTINATIONS[1] # DESTINATION[1] = snapshot_test_docker
        it 'removing snapshot with mariadb 5.5' do
          execute_bash(cmd_snapshot_remove(destination, node_name, SNAPSHOTS_NAMES[destination][:initial_mariadb])).should eql 0
        end
      else
        # Docker now using last snapshot (image) with running machine and could not be deleted
        it "trying to remove last docker snapshot, but it's not going to happened (because snapshot is in use)" do
          execute_bash(cmd_snapshot_remove(destination, node_name, SNAPSHOTS_NAMES[destination][:initial_mariadb])).should_not eql 0
        end
      end

    end

  end

end

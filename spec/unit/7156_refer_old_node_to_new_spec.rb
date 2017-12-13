require 'rspec'
require 'fileutils'
require_relative '../spec_helper'
require_relative '../../core/clone'
require_relative '../../core/out'
require_relative '../../core/session'
require_relative '../../core/helper'

TEST_PATH = 'TEST/.vagrant/machines/node0/libvirt/'
CLONED_LIBVIRT_NODE_PREFIX = File.basename $0

full_cloned_libvirt_node_name = nil

describe nil do

  before :all do
    $mdbci_exec_dir = File.absolute_path('.')
    $out = Out.new
    $session = Session.new
    $session.isSilent = false
    FileUtils.mkdir_p TEST_PATH
    File.open('TEST/provider', 'w') { |file| file.write 'libvirt' }
    root_dir = Dir.pwd

    Dir.chdir ENV['path_to_nodes_libvirt']
    execute_bash('vagrant halt')
    Dir.chdir root_dir

    full_cloned_libvirt_node_name = create_libvirt_node_clone(ENV['path_to_nodes_libvirt'], ENV['node0_libvirt'], CLONED_LIBVIRT_NODE_PREFIX)
    puts full_cloned_libvirt_node_name

    Dir.chdir ENV['path_to_nodes_libvirt']
    execute_bash('vagrant up')
    Dir.chdir root_dir
  end

  after :all do
    FileUtils.rm_rf TEST_PATH
    execute_bash("scripts/clean_vms.sh #{full_cloned_libvirt_node_name}")
  end

  it 'raise error if machine is not running' do
    lambda { set_node_machine_id('TEST', 'node0', '1234') }.should raise_error 'TEST/node0: machine is not created'
  end

  it 'raise error if machine is not running' do
    new_uuid = get_libvirt_uuid_by_domain_name(full_cloned_libvirt_node_name)
    set_node_machine_id(ENV['path_to_nodes_libvirt'], ENV['node0_libvirt'], new_uuid)
    uuid = File.read "#{ENV['path_to_nodes_libvirt']}/.vagrant/machines/#{ENV['node0_libvirt']}/libvirt/id"
    uuid.should eql new_uuid
  end

end
require 'rspec'
require_relative '../spec_helper'
require_relative '../../core/out'
require_relative '../../core/session'
require_relative '../../core/clone'

describe nil do

  new_domain_name = nil

  before :all do
    $mdbci_exec_dir = File.absolute_path('.')
    $out = Out.new
    $session = Session.new
    root_directory = Dir.pwd
    Dir.chdir ENV['path_to_nodes']
    `vagrant up #{ENV['node_name']} --provider libvirt`
    Dir.chdir root_directory
  end

  after :all do
    if new_domain_name
      `virsh undefine #{new_domain_name}`
      path_to_img = `virsh -q vol-list --pool default | grep #{new_domain_name} | awk '{print $2}'`
      `virsh vol-delete #{path_to_img}`
    end
  end

  it 'create clone of libvirt container to new image' do
    root_directory = Dir.pwd
    Dir.chdir ENV['path_to_nodes']
    `vagrant halt #{ENV['node_name']}`
    Dir.chdir root_directory
    new_domain_name = create_libvirt_node_clone(ENV['path_to_nodes'], ENV['node_name'], "#{ENV['path_to_nodes']}_clone")
    puts `virsh -q list --all | grep #{new_domain_name}`
    $?.exitstatus.should eql 0
    Dir.chdir ENV['path_to_nodes']
    `vagrant up #{ENV['node_name']} --provider libvirt`
    Dir.chdir root_directory
  end

  it 'raise error libvirt node is not in shutoff state' do
    root_directory = Dir.pwd
    Dir.chdir ENV['path_to_nodes']
    puts `vagrant up #{ENV['node_name']} --provider libvirt`
    Dir.chdir root_directory
    lambda {create_libvirt_node_clone(ENV['path_to_nodes'], ENV['node_name'], "#{ENV['path_to_nodes']}_clone")}
        .should raise_error "#{ENV['path_to_nodes']}/#{ENV['node_name']}: libvirt node is not in shutoff state (for cloning state must be shutoff)"
  end

  it 'node exists and method will not throws error' do
    uuid = get_node_machine_id(ENV['path_to_nodes'], ENV['node_name'])
    lambda {get_libvirt_domain_name_by_uuid(uuid)}.should_not raise_error
  end

  it 'node does not exist and method will throws error' do
    lambda {get_libvirt_domain_name_by_uuid('WRONG')}
        .should raise_error 'WRONG: uuid for domain is not found'
  end

  it 'method returns existing uuid' do
    puts uuid = get_node_machine_id(ENV['path_to_nodes'], ENV['node_name'])
    puts domain_name = get_libvirt_domain_name_by_uuid(uuid)
    output = execute_bash('virsh -q list --all', true)
    output.should include domain_name
  end


end
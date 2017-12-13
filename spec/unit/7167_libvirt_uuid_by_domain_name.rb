require_relative '../../core/clone'
require_relative '../../core/helper'

describe nil do

  before :all do
    $mdbci_exec_dir = File.absolute_path('.')
    $out = Out.new
    $session = Session.new
  end

  it 'node exists and method will not throws error' do
    lambda {get_libvirt_uuid_by_domain_name("#{ENV['config_name']}_#{ENV['node_name']}")}.should_not raise_error
  end

  it 'node does not exist and method will throws error' do
    lambda {get_libvirt_uuid_by_domain_name('WRONG')}
        .should raise_error 'WRONG: uuid for domain is not found'
  end

  it 'method returns existing uuid' do
    uuid = get_libvirt_uuid_by_domain_name("#{ENV['config_name']}_#{ENV['node_name']}")
    output = execute_bash('virsh -q list --uuid --all', true)
    output.should include uuid
  end

end
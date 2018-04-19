require 'rspec'
require_relative '../spec_helper'
require_relative '../../core/out'
require_relative '../../core/exception_handler'
require_relative '../../core/boxes_manager'
require_relative '../../core/session'

describe 'Session' do

  before :all do
    $mdbci_exec_dir = File.absolute_path('.')
    $session = Session.new
    $session.isSilent = true
    $session.mdbciDir = Dir.pwd
    $out = Out.new($session)
    $exception_handler = ExceptionHandler.new
    boxesPath = './BOXES'
    $session.boxes = BoxesManager.new boxesPath
    reposPath = './repo.d'
    $session.repos = RepoManager.new reposPath
    $session.keyFile = 'spec/test_machine_configurations/empty_key_file.txt'
  end

  # Before all tests must be generated configurations
  # vagrant machine must be running
  # for mdbci node must be created appropriate mdbci_template file and
  # must be prepared box with IP and keyfile location that is targeting real running machine
  # that can be accessed through ssh

  it '#publicKeys should exit with zero code for concrete mdbci/ppc64 node' do
    $session.publicKeys("#{ENV['mdbci_param_conf_ppc']}/node1").should(eql(0))
  end

  it '#publicKeys should exit with zero code for all mdbci/ppc64 nodes' do
    $session.publicKeys(ENV['mdbci_param_conf_ppc']).should(eql(0))
  end

  it '#publicKeys should exit with zero code for all mdbci/ppc64 nodes (when mdbci node is wrong)' do
    lambda{$session.publicKeys("#{ENV['mdbci_param_conf_ppc']}/NOT_EXISTS")}.should raise_error(/No such node with name .* in .*/)
  end

  it '#publicKeys should exit with zero code for all libvirt nodes' do
    $session.publicKeys(ENV['mdbci_param_conf_libvirt']).should(eql(0))
  end

  it '#publicKeys should exit with non-zero code (when argument is nil)' do
    lambda{$session.publicKeys(nil)}.should raise_error('Configuration name is required')
  end

  it '#publicKeys should exit with non-zero code (when no such machine exists)' do
    lambda{$session.publicKeys('NOT_EXISTS')}.should raise_error
  end

end

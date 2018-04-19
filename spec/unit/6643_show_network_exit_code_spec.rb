require 'rspec'
require_relative '../spec_helper'
require_relative '../../core/out'
require_relative '../../core/exception_handler'
require_relative '../../core/boxes_manager'
require_relative '../../core/session'
require_relative '../../core/network'

describe 'Session' do

  before :all do
    $mdbci_exec_dir = File.absolute_path('.')
    $session = Session.new
    $out = Out.new($session)
    $session.isSilent = true
    $session.mdbciDir = Dir.pwd
    $exception_handler = ExceptionHandler.new
    boxesPath = './BOXES'
    $session.boxes = BoxesManager.new boxesPath
    reposPath = './repo.d'
    $session.repos = RepoManager.new reposPath
    $session.command = 'ls'
  end

  # Before all tests must be generated configurations
  # vagrant machine must be running
  # for mdbci node must be created appropriate mdbci_template file and
  # must be prepared box with IP and keyfile location that is targeting real running machine
  # that can be accessed through ssh

  it '#ssh should exit with zero code for concrete mdbci/ppc64 node' do
    Network.show("#{ENV['mdbci_param_conf_ppc']}/node1").should(eql(0))
  end

  it '#ssh should exit with zero code for all mdbci/ppc64 nodes' do
    Network.show(ENV['mdbci_param_conf_ppc'].to_s).should(eql(0))
  end

  it '#ssh should exit with zero code for all mdbci/ppc64 nodes (when mdbci node is wrong)' do
    lambda{Network.show("#{ENV['mdbci_param_conf_ppc']}/NOT_EXISTS")}.should raise_error
  end

  it '#ssh should exit with zero code for all libvirt nodes' do
    Network.show(ENV['mdbci_param_conf_libvirt'].to_s).should(eql(0))
  end

  it '#ssh should exit with zero code for concrete mdbci/ppc64 node' do
    Network.show("#{ENV['mdbci_param_conf_libvirt']}/node1").should(eql(0))
  end

  it '#ssh should exit with non-zero code (when argument is nil)' do
    lambda{Network.show(nil)}.should raise_error
  end

  it '#ssh should exit with non-zero code (when no such machine exists)' do
    lambda{Network.show('NOT_EXISTS')}.should raise_error
  end

end

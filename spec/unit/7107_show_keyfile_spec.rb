require 'rspec'
require_relative '../spec_helper'
require_relative '../../core/out'
require_relative '../../core/exception_handler'
require_relative '../../core/boxes_manager'
require_relative '../../core/session'
require_relative '../../core/network'

describe 'Network' do

  before :all do
    $mdbci_exec_dir = File.absolute_path('.')
    $out = Out.new
    $session = Session.new
    $session.isSilent = true
    $session.mdbciDir = Dir.pwd
    $exception_handler = ExceptionHandler.new
    boxesPath = './BOXES'
    $session.boxes = BoxesManager.new boxesPath
    reposPath = './repo.d'
    $session.repos = RepoManager.new reposPath
  end

  it '#showKeyFile should exit with zero code for concrete mdbci/ppc64 node' do
    Network.showKeyFile("#{ENV['mdbci_param_conf_ppc']}/node1").should(eql(0))
  end

  it '#showKeyFile should exit with zero code for mdbci/ppc64 nodes' do
    Network.showKeyFile(ENV['mdbci_param_conf_ppc']).should(eql(0))
  end

  it '#showKeyFile should raise exception for mdbci/ppc64 node (when no such node exists)' do
    lambda{Network.showKeyFile("#{ENV['mdbci_param_conf_ppc']}/NOT_EXIST")}.should raise_error /MDBCI node is not found in .*/
  end

  it '#showKeyFile should show keyfile for docker nodes' do
    Network.showKeyFile(ENV['mdbci_param_conf_libvirt']).should(eql(0))
  end

  it '#showKeyFile should raise exception for all nodes (when arguments are nil)' do
    lambda{Network.showKeyFile(nil)}.should(raise_error(RuntimeError, 'Configuration name is required'))
  end

  it '#showKeyFile should raise exception for aws/vbox nodes nodes (when no such node exists)' do
    lambda{Network.showKeyFile('NOT_EXISTS')}.should(raise_error(RuntimeError, 'Configuration with such name does not exists'))
  end

end
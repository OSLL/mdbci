require 'rspec'
require_relative '../spec_helper'
require_relative '../../core/out'
require_relative '../../core/exception_handler'
require_relative '../../core/boxes_manager'
require_relative '../../core/session'

describe 'Session' do

  DOCKER_CONF = ENV['mdbci_param_conf_docker']
  PPC_CONF = ENV['mdbci_param_conf_ppc']

  before :all do
    $mdbci_exec_dir = ENV['WORKSPACE']
    $out = Out.new
    $session = Session.new
    $session.isSilent = true
    $session.mdbciDir = Dir.pwd
    $exception_handler = ExceptionHandler.new
    boxesPath = './BOXES'
    $session.boxes = BoxesManager.new boxesPath
    reposPath = './repo.d'
    $session.repos = RepoManager.new reposPath
    $session.command = 'ls'
  end


  it '#ssh should exit with zero code for concrete mdbci/ppc64 node' do
    $session.ssh("#{PPC_CONF}/node1").should(eql(0))
  end

  it '#ssh should exit with zero code for all mdbci/ppc64 nodes' do
    $session.ssh(PPC_CONF).should(eql(0))
  end

  it '#ssh should exit with zero code for all docker nodes' do
    $session.ssh("#{DOCKER_CONF}/node1").should(eql(0))
  end

  it '#ssh should exit with zero code for all docker nodes' do
    $session.ssh(DOCKER_CONF).should(eql(0))
  end

  it '#ssh should raise error (when no such machine exists)' do
    lambda{$session.ssh('TEST_MACHINE')}.should raise_error('Machine with such name: TEST_MACHINE does not exist')
  end

  it '#ssh should raise error (when no such machine exists)' do
    lambda{$session.ssh(nil)}.should raise_error('Configuration name is required')
  end

  it '#ssh should raise error (when no such machine exists)' do
    lambda{$session.ssh("#{DOCKER_CONF}/NOT_EXIST")}.should raise_error("node with such name does not exist in #{DOCKER_CONF}: NOT_EXIST")
  end

  it '#ssh should raise error (when no such machine exists)' do
    lambda{$session.ssh("#{PPC_CONF}/NOT_EXIST")}.should raise_error("mdbci node with such name does not exist in #{PPC_CONF}: NOT_EXIST")
  end

end

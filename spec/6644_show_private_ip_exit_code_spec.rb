require 'rspec'
require 'spec_helper'
require_relative '../core/out'
require_relative '../core/exception_handler'
require_relative '../core/boxes_manager'
require_relative '../core/session'
require_relative '../core/network'

describe 'Session' do

  before :all do
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

  # Before all tests must be generated configurations
  # vagrant machine must be running
  # for mdbci node must be created appropriate mdbci_template file and
  # must be prepared box with IP and keyfile location that is targeting real running machine
  # that can be accessed through ssh

  it '#ssh should exit with zero code for concrete mdbci/ppc64 node' do
    Network.private_ip(ENV['pathToConfigToMDBCINode'].to_s).should(eql(0))
  end

  it '#ssh should exit with zero code for all mdbci/ppc64 nodes' do
    Network.private_ip(ENV['pathToConfigToMDBCIFolder'].to_s).should(eql(0))
  end

  it '#ssh should exit with zero code for all mdbci/ppc64 nodes (when mdbci node is wrong)' do
    Network.private_ip(ENV['pathToConfigToMDBCIFolder'].to_s + '/NOT_EXISTS').should(eql(1))
  end

  it '#ssh should exit with zero code for all aws/vbox nodes' do
    Network.private_ip(ENV['pathToConfigToVBOXNode'].to_s).should(eql(0))
  end

  it '#ssh should exit with non-zero code for mdbci/ppc64 nodes (when box parameter does npt exists)' do
    Network.private_ip(ENV['pathToConfigToMDBCIBadNode'].to_s).should(eql(1))
  end

  it '#ssh should exit with non-zero code (when argument is nil)' do
    Network.private_ip(nil).should(eql(1))
  end

  it '#ssh should exit with non-zero code (when no such machine exists)' do
    Network.private_ip('NOT_EXISTS').should(eql(1))
  end

end
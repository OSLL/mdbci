require 'rspec'
require_relative '../spec_helper'
require_relative '../../core/out'
require_relative '../../core/exception_handler'
require_relative '../../core/boxes_manager'
require_relative '../../core/session'
require_relative '../../core/network'

describe 'Network' do

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
  end

  it '#showKeyFile should exit with zero code for concrete mdbci/ppc64 node' do
    Network.showKeyFile(ENV['pathToConfigToMDBCINode']).should(eql(0))
  end

  it '#showKeyFile should exit with zero code for mdbci/ppc64 nodes' do
    Network.showKeyFile(ENV['pathToConfigToMDBCIFolder']).should(eql(0))
  end

  it '#showKeyFile should exit with non-zero code for mdbci/ppc64 node (when no such node exists)' do
    Network.showKeyFile(ENV['pathToConfigToMDBCIFolder']+'/NOT_EXISTS').should(eql(1))
  end

  it '#showKeyFile should exit with non-zero code for concrete mdbci/ppc64 node (bad keyfile path)' do
    Network.showKeyFile(ENV['pathToConfigToMDBCIBadNode']).should(eql(1))
  end

  it '#showKeyFile should exit with zero code for aws/vbox nodes nodes' do
    Network.showKeyFile(ENV['pathToConfigToVBOXNode']).should(eql(0))
  end

  it '#showKeyFile should exit with non-zero code for all nodes (when arguments are nil)' do
    Network.showKeyFile(nil).should(eql(1))
  end

  it '#showKeyFile should exit with non-zero code for aws/vbox nodes nodes (when no such node exists)' do
    Network.showKeyFile('NOT_EXISTS').should(eql(1))
  end

end
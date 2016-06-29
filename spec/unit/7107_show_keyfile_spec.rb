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

=begin
  it '#showKeyFile should exit with zero code for concrete mdbci/ppc64 node' do
    Network.showKeyFile(ENV['pathToConfigToMDBCINode']).should(eql(0))
  end

  it '#showKeyFile should exit with zero code for mdbci/ppc64 nodes' do
    Network.showKeyFile(ENV['pathToConfigToMDBCIFolder']).should(eql(0))
  end

  it '#showKeyFile should raise exception for mdbci/ppc64 node (when no such node exists)' do
    lambda{Network.showKeyFile(ENV['pathToConfigToMDBCIFolder']+'/NOT_EXISTS')}.should(raise_error(RuntimeError, "MDBCI nodes are not found in"+ENV['pathToConfigToMDBCIFolder']));
  end

  it '#showKeyFile should raise exception for concrete mdbci/ppc64 node (bad keyfile path)' do
    lambda{Network.showKeyFile(ENV['pathToConfigToMDBCIBadNode'])}.should(raise_error(RuntimeError, "/Key file.* is not found for node.*/"));
  end
=end

  it '#showKeyFile should show keyfile for aws/vbox nodes' do
    Network.showKeyFile(ENV['configPathToVBOXNode']).should(eql(0))
  end

  it '#showKeyFile should raise exception for all nodes (when arguments are nil)' do
    lambda{Network.showKeyFile(nil)}.should(raise_error(RuntimeError, 'Configuration name is required'))
  end

  it '#showKeyFile should raise exception for aws/vbox nodes nodes (when no such node exists)' do
    lambda{Network.showKeyFile('NOT_EXISTS')}.should(raise_error(RuntimeError, 'Configuration with such name does not exists'))
  end

end
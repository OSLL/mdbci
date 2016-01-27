require 'rspec'
require 'spec_helper'
require_relative '../core/out'
require_relative '../core/exception_handler'
require_relative '../core/boxes_manager'
require_relative '../core/session'

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

  it '#ssh should exit with zero code for mdbci/ppc64 nodes' do
    # should be initialized machine to test mdbci/ppc64 nodes
    # $session.ssh('TEST_MACHINE').should(eql(0))
  end

  it '#ssh should exit with non-zero code for mdbci/ppc64 nodes' do
    # should be initialized machine to test mdbci/ppc64 nodes
    # $session.ssh('TEST_MACHINE').should(eql(1))
  end

  it '#ssh should exit with zero code for aws/vbox nodes nodes' do
    $session.ssh(ENV['pathToConfig'].to_s).should(eql(0))
  end

  it '#ssh should exit with non-zero code for aws/vbox nodes nodes' do
    $session.ssh('TEST_MACHINE').should(eql(1))
  end

end

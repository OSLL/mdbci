require 'rspec'
require_relative '../spec_helper'
require_relative '../../core/out'
require_relative '../../core/exception_handler'
require_relative '../../core/boxes_manager'
require_relative '../../core/session'

describe 'Session' do

  before :all do
    $out = Out.new
    $session = Session.new
    $session.mdbciDir = Dir.pwd
    $exception_handler = ExceptionHandler.new
    boxesPath = './BOXES'
    $session.boxes = BoxesManager.new boxesPath
    reposPath = './repo.d'
    $session.repos = RepoManager.new reposPath
    $session.command = 'ls'
  end

  it '#sudo should exit with zero code for libvirt nodes nodes' do
    $session.sudo("#{ENV['mdbci_param_conf_libvirt']}/node1").should(eql(0))
  end

  it '#sudo should exit with zero code for docker nodes nodes' do
    $session.sudo("#{ENV['mdbci_param_conf_docker']}/node1").should(eql(0))
  end

  it '#sudo should exit with non-zero code for aws/vbox nodes nodes (no such machine exists)' do
    lambda{$session.sudo('TEST_MACHINE')}.should raise_error
  end

end

require 'rspec'
require_relative '../spec_helper'
require_relative '../../core/out'
require_relative '../../core/exception_handler'
require_relative '../../core/boxes_manager'
require_relative '../../core/session'

describe 'Session' do

  before :all do
    $mdbci_exec_dir = File.expand_path(File.dirname(__FILE__))
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

  it '#getBoxNameByPath should return name for aws/vbox node' do
    $session.boxes.getBoxNameByPath('spec/test_machine_configurations/6821_test_conf/node0').should(eql('centos_6_vbox'))
  end

  it '#getBoxNameByPath should raise wrong node' do
    lambda{$session.boxes.getBoxNameByPath('spec/test_machine_configurations/6821_test_conf/node123')}.should(raise_error(RuntimeError, /Node .* is not found in .*/))
  end

  it '#getBoxNameByPath should raise wrong path' do
    lambda{$session.boxes.getBoxNameByPath('WRONG_PATH')}.should(raise_error(RuntimeError, 'Path to generated nodes configurations is wrong'))
  end

end
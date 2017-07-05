require 'rspec'
require_relative '../spec_helper'
require_relative '../../core/out'
require_relative '../../core/exception_handler'
require_relative '../../core/boxes_manager'
require_relative '../../core/session'

describe 'Session' do

  box_should_be_removed = nil

  before :all do
    $mdbci_exec_dir = File.expand_path(File.dirname(__FILE__))
    $out = Out.new
    $session = Session.new
    $session.isSilent = true
    $session.mdbciDir = Dir.pwd
    $exception_handler = ExceptionHandler.new
    boxesPath = 'spec/configs/boxes/'
    $session.boxes = BoxesManager.new boxesPath
    reposPath = './repo.d'
    $session.repos = RepoManager.new reposPath
    box_should_be_removed = `vagrant box list | grep 'baremettle/ubuntu-14.04'`.empty?
  end

  after :all do
    `vagrant box remove baremettle/ubuntu-14.04 --provider libvirt`if box_should_be_removed
  end

  it '#setup should exit with zero exit code when parameter \'boxes\' is defined' do
    $session.setup('boxes').should(eql(0))
  end

  it '#setup should exit with non-zero exit code when parameter is wrong or shell command failed' do
    lambda{$session.setup('')}.should raise_error /Cannot setup .*/
  end

end

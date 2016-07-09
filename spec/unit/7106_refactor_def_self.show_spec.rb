require 'rspec'
require_relative '../spec_helper'
require_relative '../../core/out'
require_relative '../../core/exception_handler'
require_relative '../../core/boxes_manager'
require_relative '../../core/session'
require_relative '../../core/network'

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
  end

  # Before all tests must be generated configurations
  # vagrant machine must be running
  # for mdbci node must be created appropriate mdbci_template file and
  # must be prepared box with IP and keyfile location that is targeting real running machine
  # that can be accessed through ssh

  it '#network should raise not running nodes' do
    lambda{Network.show(ENV['pathToStoppedConfigToNode'].to_s)}.should(raise_error(RuntimeError, /Incorrect node.*/))
  end

  it '#network should return IP for nodes' do
    lambda{Network.show(ENV['pathToConfigToNode'].to_s)}.should eq(/.+\..+\..+\..+/) # Regexp 127.0.0.1
  end

  it '#network should raise wrong node' do
    lambda{Network.show(ENV['pathToConfigToNode'].to_s+'\WRONG_NODE')}.should(raise_error(RuntimeError, /Configuration not found: .*/))
  end

  it '#network should raise wrong path' do
    lambda{Network.show('WRONG_PATH')}.should(raise_error(RuntimeError, /Configuration not found: .*/))
  end

  it '#network should raise nil argument' do
    lambda{Network.show(nil)}.should(raise_error(RuntimeError, 'Configuration name is required'))
  end

end
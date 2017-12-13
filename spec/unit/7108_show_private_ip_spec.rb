require 'rspec'
require_relative '../spec_helper'

require_relative '../../core/session'
require_relative '../../core/node_product'
require_relative '../../core/out'
require_relative '../../core/repo_manager'
require_relative '../../core/exception_handler'
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
    $session.awsConfigFile='aws-config.yml'
    $session.loadCollections
  end

  it 'show private IP should show IP and Node' do
    Network.private_ip(ENV['configPath']).should eq(0)
  end

  it 'show private IP should raise error: not set config name ' do
    lambda{Network.private_ip(nil)}.should raise_error(RuntimeError,"Configuration name is required")
  end

  it 'show private IP should raise error: not find directory ' do
    lambda{Network.private_ip("SOME_WRONG_PATH")}.should raise_error(RuntimeError,/Can not find directory .*/)
  end
 end
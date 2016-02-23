require 'fileutils'

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

  # Before all tests must be generated configurations
  # vagrant machine must be running
  # for mdbci node must be created appropriate mdbci_template file and
  # must be prepared box with IP and keyfile location that is targeting real running machine
  # that can be accessed through ssh

  it '#generate should exit with non-zero when configuration file is not specified' do
    $session.generate(ENV['pathToGenerationDestination']).should eql 1
  end

  it '#generate should exit with zero when there is no destination specified (vbox...)' do
    $session.configFile = ENV['pathToVBOXConfigFile']
    $session.generate(nil).should eql 0
    FileUtils.rm_rf('default')  # already delete temporary files
  end

  it '#generate should exit with zero when there is no destination specified (mdbci...)' do
    $session.configFile = ENV['pathToMDBCIConfigFile']
    $session.generate(nil).should eql 0
    FileUtils.rm_rf('default')
  end

  it '#generate should exit with zero for vbox' do
    $session.configFile = ENV['pathToVBOXConfigFile']
    $session.generate(ENV['pathToDestination']).should eql 0
    FileUtils.rm_rf ENV['pathToDestination']
  end

  it '#generate should exit with zero for mdbci' do
    $session.configFile = ENV['pathToMDBCIConfigFile']
    $session.generate(ENV['pathToDestination']).should eql 0
    FileUtils.rm_rf ENV['pathToDestination']
  end

end
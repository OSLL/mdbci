require 'rspec'
require_relative '../spec_helper'

require_relative '../../core/session'
require_relative '../../core/node_product'
require_relative '../../core/out'
require_relative '../../core/services/repo_manager'
require_relative '../../core/exception_handler'

describe 'Session.showBoxes' do

  before :all do
    $mdbci_exec_dir = File.absolute_path('.')
    $session = Session.new
    $out = Out.new($session)
    $session.isSilent = true
    $session.mdbciDir = Dir.pwd
    $exception_handler = ExceptionHandler.new
    boxesPath = './BOXES'
    $session.boxes = BoxesManager.new boxesPath
    reposPath = './config/repo.d'
    $session.repos = RepoManager.new reposPath
    $session.command = 'ls'
  end

  it 'show boxes ubuntu trusty' do
    $session.boxPlatform = 'ubuntu'
    $session.boxPlatformVersion = 'trusty'
    exit_code = $session.showBoxes
    exit_code.should eq(0)
  end
  #
  it 'show boxes ubuntu 7' do
    $session.boxPlatform = 'ubuntu'
    $session.boxPlatformVersion = '7'
    exit_code = $session.showBoxes
    exit_code.should eq(1)
  end
  #
  it 'show boxes debian jessie' do
    $session.boxPlatform = 'debian'
    $session.boxPlatformVersion = 'jessie'
    exit_code = $session.showBoxes
    exit_code.should eq(0)
  end
  #
  it 'show boxes centos 7' do
    $session.boxPlatform = 'centos'
    $session.boxPlatformVersion = '7'
    exit_code = $session.showBoxes
    exit_code.should eq(0)
  end
  #
  it 'show boxes debian gessie' do
    $session.boxPlatform = 'debian'
    $session.boxPlatformVersion = 'gessie'
    exit_code = $session.showBoxes
    exit_code.should eq(1)
  end
  #
  it 'show boxes centos 8' do
    $session.boxPlatform = 'centos'
    $session.boxPlatformVersion = '8'
    exit_code = $session.showBoxes
    exit_code.should eq(1)
  end
end

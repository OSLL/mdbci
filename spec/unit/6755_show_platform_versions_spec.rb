require 'rspec'
require_relative '../spec_helper'
require_relative '../../core/out'
require_relative '../../core/exception_handler'
require_relative '../../core/boxes_manager'
require_relative '../../core/session'

describe 'Session.boxesPlatformVersions' do

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

  it '#boxesPlatformVersions.ubuntu' do
    $session.boxPlatform = 'ubuntu'
    exit_code = $session.boxesPlatformVersions
    exit_code.should eq(0)

  end

  it '#boxesPlatformVersions.centos' do
    $session.boxPlatform = 'centos'
    exit_code = $session.boxesPlatformVersions
    exit_code.should eq(0)

  end

  it '#boxesPlatformVersions.debian' do
    $session.boxPlatform = 'debian'
    exit_code = $session.boxesPlatformVersions
    exit_code.should eq(0)

  end

  it '#boxesPlatformVersions.opesuse' do
    $session.boxPlatform = 'opensuse'
    exit_code = $session.boxesPlatformVersions
    exit_code.should eq(0)

  end

  it '#boxesPlatformVersions.ubuntu_trusty' do
    $session.boxPlatform = 'ubuntu_trusty'
    exit_code = $session.boxesPlatformVersions
    exit_code.should eq(1)

  end

  it '#boxesPlatformVersions.debian7' do
    $session.boxPlatform = 'debian7'
    exit_code = $session.boxesPlatformVersions
    exit_code.should eq(1)

  end

  it '#boxesPlatformVersions.centos6' do
    $session.boxPlatform = 'centos6'
    exit_code = $session.boxesPlatformVersions
    exit_code.should eq(1)

  end

end
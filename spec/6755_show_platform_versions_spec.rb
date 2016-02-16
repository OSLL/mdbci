require 'rspec'
require 'spec_helper'
require_relative '../core/out'
require_relative '../core/exception_handler'
require_relative '../core/boxes_manager'
require_relative '../core/session'

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

    exit_code = $session.boxesPlatformVersions('ubuntu')
    exit_code.should eq(0)

  end

  it '#boxesPlatformVersions.centos' do

    exit_code = $session.boxesPlatformVersions('centos')
    exit_code.should eq(0)

  end

  it '#boxesPlatformVersions.debian' do

    exit_code = $session.boxesPlatformVersions('debian')
    exit_code.should eq(0)

  end

  it '#boxesPlatformVersions.opesuse' do

    exit_code = $session.boxesPlatformVersions('opensuse')
    exit_code.should eq(0)

  end

  it '#boxesPlatformVersions.ubuntu_trusty' do

    exit_code = $session.boxesPlatformVersions('ubuntu_trusty')
    exit_code.should eq(1)

  end

  it '#boxesPlatformVersions.debian7' do

    exit_code = $session.boxesPlatformVersions('debian7')
    exit_code.should eq(1)

  end

  it '#boxesPlatformVersions.centos6' do

    exit_code = $session.boxesPlatformVersions('centos6')
    exit_code.should eq(1)

  end

end
require 'rspec'
require_relative '../spec_helper'
require_relative '../../core/out'
require_relative '../../core/exception_handler'
require_relative '../../core/boxes_manager'
require_relative '../../core/session'

describe 'Session.getBoxesPlatformVersions' do

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

  it '#getBoxesPlatformVersions.ubuntu' do
  	boxesList = Array.new
    boxesList = ["precise"]
    boxes_versions = $session.getBoxesPlatformVersions('ubuntu', $session.boxes.boxesManager)
    boxes_versions.should eq(boxesList)
  end

  it '#getBoxesPlatformVersions.centos' do
  	boxesList = Array.new
    boxesList = []
    boxes_versions = $session.getBoxesPlatformVersions('centos', $session.boxes.boxesManager)
    boxes_versions.should eq(boxesList)

  end

  it '#getBoxesPlatformVersions.debian' do
    boxes_versions = $session.getBoxesPlatformVersions('debian', $session.boxes.boxesManager)
    boxes_versions.should eq(0)

  end

  it '#getBoxesPlatformVersions.opesuse' do
    boxes_versions = $session.getBoxesPlatformVersions('opensuse', $session.boxes.boxesManager)
    boxes_versions.should eq(0)

  end

  it '#getBoxesPlatformVersions.ubuntu_trusty' do
    boxes_versions = $session.getBoxesPlatformVersions('ubuntu_trusty', $session.boxes.boxesManager)
    boxes_versions.should eq(1)

  end

  it '#getBoxesPlatformVersions.debian7' do
    boxes_versions = $session.getBoxesPlatformVersions('debian7', $session.boxes.boxesManager)
    boxes_versions.should eq(1)

  end

  it '#getBoxesPlatformVersions.centos6' do
    boxes_versions = $session.getBoxesPlatformVersions('debian7', $session.boxes.boxesManager)
    boxes_versions.should eq(1)

  end

end
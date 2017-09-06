require 'rspec'
require_relative '../spec_helper'
require_relative '../../core/out'
require_relative '../../core/exception_handler'
require_relative '../../core/boxes_manager'
require_relative '../../core/session'

describe 'Session.getBoxesPlatformVersions' do

  before :all do
    $mdbci_exec_dir = ENV['WORKSPACE']
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
    boxesList = ["wily", "vivid", "trusty", "precise", "utopic"]
    boxes_versions = $session.getBoxesPlatformVersions('ubuntu', $session.boxes.boxesManager)
    boxes_versions.sort.should eq(boxesList.sort)
  end

  it '#getBoxesPlatformVersions.centos' do
  	boxesList = Array.new
    boxesList = ["7", "6", "5"]
    boxes_versions = $session.getBoxesPlatformVersions('centos', $session.boxes.boxesManager)
    boxes_versions.sort.should eq(boxesList.sort)

  end

  it '#getBoxesPlatformVersions.debian' do
  	boxesList = Array.new
  	boxesList = ["jessie", "squeeze", "wheezy"]
    boxes_versions = $session.getBoxesPlatformVersions('debian', $session.boxes.boxesManager)
    boxes_versions.sort.should eq(boxesList.sort)

  end

  it '#getBoxesPlatformVersions.opesuse' do
  	boxesList = Array.new
  	boxesList = ["13"]
    boxes_versions = $session.getBoxesPlatformVersions('opensuse', $session.boxes.boxesManager)
    boxes_versions.should eq(boxesList)

  end

  it '#getBoxesPlatformVersions.ubuntu_trusty' do
  	boxesList = Array.new
  	boxesList = []
    boxes_versions = $session.getBoxesPlatformVersions('ubuntu_trusty', $session.boxes.boxesManager)
    boxes_versions.should eq(boxesList)

  end

  it '#getBoxesPlatformVersions.debian7' do
  	boxesList = Array.new
  	boxesList = []
    boxes_versions = $session.getBoxesPlatformVersions('debian7', $session.boxes.boxesManager)
    boxes_versions.should eq(boxesList)

  end

  it '#getBoxesPlatformVersions.centos6' do
  	boxesList = Array.new
  	boxesList = []
    boxes_versions = $session.getBoxesPlatformVersions('debian7', $session.boxes.boxesManager)
    boxes_versions.should eq(boxesList)

  end

end
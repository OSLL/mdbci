require 'rspec'
require_relative '../spec_helper'
require_relative '../../core/out'
require_relative '../../core/exception_handler'
require_relative '../../core/boxes_manager'
require_relative '../../core/session'

describe 'Session.showBoxNameByPath' do

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
    boxesList = ["trusty", "utopic", "precise", "wily", "vivid"]
    resultList = $session.boxesPlatformVersions
    resultList.sort.should eq(boxesList.sort)
  end

  it '#boxesPlatformVersions.centos' do
    $session.boxPlatform = 'centos'
    boxesList = ["5", "6", "7"]
    resultList = $session.boxesPlatformVersions
    resultList.sort.should eq(boxesList.sort)
  end

  it '#boxesPlatformVersions.debian' do
    $session.boxPlatform = 'debian'
    boxesList = ["wheezy", "jessie", "squeeze"]
    resultList = $session.boxesPlatformVersions
    resultList.sort.should eq(boxesList.sort)
  end

  it '#boxesPlatformVersions.opesuse' do
    $session.boxPlatform = 'opesuse'
    boxesList = ["13"]
    resultList = $session.boxesPlatformVersions
    resultList.should eq(boxesList)
  end

  it '#boxesPlatformVersions.debian123213' do
    $session.boxPlatform = 'debian123123'
    boxesList = []
    resultList = $session.boxesPlatformVersions
    resultList.should eq(boxesList)
  end


end
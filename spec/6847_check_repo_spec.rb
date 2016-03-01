require 'fileutils'

require 'rspec'
require 'spec_helper'
require_relative '../core/out'
require_relative '../core/exception_handler'
require_relative '../core/boxes_manager'
require_relative '../core/session'
require_relative '../core/generator'

describe 'Generator' do

  before :all do
    $out = Out.new
    $session = Session.new
    $session.isSilent = true
    $session.mdbciDir = Dir.pwd
    $exception_handler = ExceptionHandler.new
    boxesPath = './BOXES'
    $session.boxes = BoxesManager.new boxesPath
  end

  it '#proceedRepoLink should return link with substituted $basearch substring with x86_64/repodata/' do
    Generator.proceedRepoLink('http//TEST/$basearch').should eql ['http//TEST/x86_64/repodata/']
  end

  it '#proceedRepoLink should return link with substituted os config, devided with spaces, with /os//dists/verison/main' do
    Generator.proceedRepoLink('http://TEST/debian sqeeze main').should eql ["http://TEST//debian/dists/sqeeze/main/binary-amd64", "http://TEST//debian/dists/sqeeze/main/binary-i386"]
  end

  it '#proceedRepoLink should return same link' do
    Generator.proceedRepoLink('http://TEST/TEST').should eql ["http://TEST/TEST"]
  end

  it '#proceedRepoLink should return same link' do
    Generator.proceedRepoLink('http://TEST/TEST').should eql ["http://TEST/TEST"]
  end

  it '#checkRepoLinks should raise error' do
    lambda {Generator.checkRepoLinks(["http://maxscale-jenkins.mariadb.com/ci-repository/develop/mariadb-maxscale//centos/7/$basearch"], "TEST")}.should raise_error
  end

  it '#checkRepoLinks should be executed successefull' do
    lambda {Generator.checkRepoLinks(["http://maxscale-jenkins.mariadb.com/ci-repository/develop/mariadb-maxscale//centos/6/$basearch"], "TEST")}.should_not raise_error
  end
end

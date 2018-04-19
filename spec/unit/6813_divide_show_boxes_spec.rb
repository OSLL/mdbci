require 'rspec'
require_relative '../spec_helper'

require_relative '../../core/session'
require_relative '../../core/node_product'
require_relative '../../core/out'
require_relative '../../core/repo_manager'
require_relative '../../core/exception_handler'

describe 'BoxesManager#showBoxesget' do

  before :all do
    $mdbci_exec_dir = File.absolute_path('.')
    $session = Session.new
    $out = Out.new($session)
    $session.isSilent = true
    $session.mdbciDir = Dir.pwd
    $exception_handler = ExceptionHandler.new
    boxesPath = './BOXES'
    $session.boxes = BoxesManager.new boxesPath
    reposPath = './repo.d'
    $session.repos = RepoManager.new reposPath
  end

  it 'get boxes list ubuntu trusty' do
    boxesList = Array.new
    boxesList = ["ubuntu_trusty_libvirt", "ubuntu_trusty_docker", "ubuntu_trusty_vbox", "ubuntu_trusty_aws"]
    BoxesManager.getBoxesList('ubuntu', 'trusty')
    $session.boxes.boxesList.sort.should eq(boxesList.sort)
  end

  it 'get boxes list ubuntu trusty exit_code 0' do
    exit_code = BoxesManager.getBoxesList('ubuntu', 'trusty')
    exit_code.should eq(0)
  end

  it 'get boxes list ubuntu 7 exit_code 1' do
    exit_code = BoxesManager.getBoxesList('ubuntu', '7')
    exit_code.should eq(1)
  end

  it 'print boxes list ubuntu trusty exit_code' do
    boxesList = Array.new
    boxesList = ["ubuntu_trusty_libvirt", "ubuntu_trusty_docker", "ubuntu_trusty_vbox", "ubuntu_trusty_aws"]
    $session.boxPlatform = 'ubuntu'
    $session.boxPlatformVersion = 'trusty'
    exit_code = BoxesManager.printBoxes(boxesList)
    exit_code.should eq(0)
  end

  it 'get boxes list centos 7' do
    boxesList = Array.new
    boxesList = ["centos_7_libvirt", "centos_7_docker", "centos_7_aws", "centos_7_aws_large"]
    exit_code = BoxesManager.getBoxesList('centos', '7')
    $session.boxes.boxesList.sort.should eq(boxesList.sort)
  end

  it 'get boxes list centos trusty exit_code 0' do
    exit_code = BoxesManager.getBoxesList('centos', '7')
    exit_code.should eq(0)
  end

  it 'get boxes list centos 7 exit_code 1' do
    exit_code = BoxesManager.getBoxesList('centos', 'trusty')
    exit_code.should eq(1)
  end

  it 'print boxes list centos 7 exit_code' do
    boxesList = Array.new
    boxesList = ["centos_7_libvirt", "centos_7_docker", "centos_7_aws", "centos_7_aws_large"]
    $session.boxPlatform = 'centos'
    $session.boxPlatformVersion = '7'
    exit_code = BoxesManager.printBoxes(boxesList)
    exit_code.should eq(0)
  end

  before :each do
    $session.boxes.boxesList = Array.new
  end

end

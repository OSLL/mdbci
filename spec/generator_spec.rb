require 'rspec'
require 'spec_helper'
require 'json'
require 'fileutils'
require_relative '../core/generator'
require_relative '../core/session'
require_relative '../core/boxes_manager'
require_relative '../core/out'
require_relative '../core/exception_handler'

describe "Generator" do

  describe '.nodeDefinition' do

    # Next configuration is changing in tests (box is changed and/or aws config file path added)
    before :each do
      @testNodeString = <<EOF
{
  "testNode" :
  {
    "hostname" : "test",
    "box" : "centos6",
    "product" :
    {
      "name": "galera",
      "version"  : "10.0",
      "cnf_template" : "server1.cnf",
      "cnf_template_path" : "../cnf",
      "node_name" : "test"
    }
  }
}
EOF
    end

    # Initialising all variables that is used in Generator.nodeDefenition
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

    # If role file created then it will be deleted after each test
    after :each do
      rolePath = Dir.pwd + '/testNode.json'
      File.delete rolePath if File.exists? rolePath
      dockerDir = rolePath = Dir.pwd + '/testNode/'
      FileUtils.rm_rf dockerDir
    end

    it 'generates virtual box node definition' do
      nodes = JSON.parse @testNodeString
      nodes['testNode']['box'] = 'centos6'
      nodes .each do |node|
        roleFile = File.open Dir.pwd + '/spec/data_to_test/6589_test_vbox_role_node_definition.json', 'r'
        roleFileContent = roleFile.read
        vagrantfileFile = File.open Dir.pwd + '/spec/data_to_test/6589_test_vbox_vagrantfile_node_definition.txt', 'r'
        vagrantfileContent = vagrantfileFile.read
        vagrantfileContent = "\n" + vagrantfileContent
        Generator.nodeDefinition(node,  $session.boxes, Dir.pwd, '../recipes/cookbooks/')
            .delete(' ')
            .should eql vagrantfileContent.delete(' ')
        testRoleFile = File.open Dir.pwd + '/testNode.json', 'r'
        testRoleFile.read.should eql roleFileContent
      end
    end

    it 'generates aws box node definition' do
      nodes = JSON.parse @testNodeString
      nodes['testNode']['box'] = 'centos7'
      nodes .each do |node|
        roleFile = File.open Dir.pwd + '/spec/data_to_test/6589_test_aws_role_node_definition.json', 'r'
        roleFileContent = roleFile.read
        vagrantfileFile = File.open Dir.pwd + '/spec/data_to_test/6589_test_aws_vagrantfile_node_definition.txt', 'r'
        vagrantfileContent = vagrantfileFile.read
        vagrantfileContent = "\n" + vagrantfileContent
        Generator.nodeDefinition(node,  $session.boxes, Dir.pwd, '../recipes/cookbooks/')
            .delete(' ')
            .should eql vagrantfileContent.delete(' ')
        testRoleFile = File.open Dir.pwd + '/testNode.json', 'r'
        testRoleFile.read.should eql roleFileContent
      end
    end

    it 'generates qemu box node definition' do
      nodes = JSON.parse @testNodeString
      nodes['testNode']['box'] = 'centos_7.0_libvirt'
      nodes .each do |node|
        roleFile = File.open Dir.pwd + '/spec/data_to_test/6589_test_qemu_role_node_definition.json', 'r'
        roleFileContent = roleFile.read
        vagrantfileFile = File.open Dir.pwd + '/spec/data_to_test/6589_test_qemu_vagrantfile_node_definition.txt', 'r'
        vagrantfileContent = vagrantfileFile.read
        vagrantfileContent = "\n" + vagrantfileContent
        Generator.nodeDefinition(node,  $session.boxes, Dir.pwd, '../recipes/cookbooks/')
            .delete(' ')
            .should eql vagrantfileContent.delete(' ')
        testRoleFile = File.open Dir.pwd + '/testNode.json', 'r'
        testRoleFile.read.should eql roleFileContent
      end
    end

    it 'generates docker box node definition' do
      nodes = JSON.parse @testNodeString
      nodes['testNode']['box'] = 'centos_7_docker'
      nodes .each do |node|
        roleFile = File.open Dir.pwd + '/spec/data_to_test/6589_test_docker_role_node_definition.json', 'r'
        roleFileContent = roleFile.read
        vagrantfileFile = File.open Dir.pwd + '/spec/data_to_test/6589_test_docker_vagrantfile_node_definition.txt', 'r'
        vagrantfileContent = vagrantfileFile.read
        vagrantfileContent = "\n" + vagrantfileContent
        Generator.nodeDefinition(node,  $session.boxes, Dir.pwd, '../recipes/cookbooks/')
            .delete(' ')
            .should eql vagrantfileContent.delete(' ')
        testRoleFile = File.open Dir.pwd + '/testNode.json', 'r'
        testRoleFile.read.should eql roleFileContent
      end
    end

  end

  # TODO
  it "Check generator" do
    # Generator.generate(path, config, boxes, override, provider)
  end

  #
  # tests for virtualbox
  context '.Vagrantfile' do

    it "Check Vagrantfile header" do
      vagrantFileHeader = Generator.vagrantFileHeader
      Generator.vagrantFileHeader.should eq(vagrantFileHeader)
    end

    it "Check Vagrantfile config header" do
      configHeader = Generator.vagrantConfigHeader
      Generator.vagrantConfigHeader.should eq(configHeader)
    end

    it "Check Vagrantfile config footer" do
      configFooter = Generator.vagrantConfigFooter
      Generator.vagrantConfigFooter.should eq(configFooter)
    end

    it "Check Vagrantfile footer" do
      vagrantFooter = Generator.vagrantFooter
      Generator.vagrantFooter.should eq(vagrantFooter)
    end

  end
  #
  # tests for virtualbox
  context '.VBOX' do

    it "Check Vagrantfile provider config" do
      $session = Session.new
      $session.nodesProvider = 'virtualbox'
      providerConfig = Generator.providerConfig
      Generator.providerConfig.should eq(providerConfig)
    end

    it "Check VBOX vm definition" do
      vm_def = Generator.getVmDef('../cookbooks/recipes', 'node0', 'node0', 'ubuntu_trusty', '1024', './cnf', true)
      Generator.getVmDef('../cookbooks/recipes', 'node0', 'node0', 'ubuntu_trusty', '1024', './cnf', true).should eq(vm_def)
    end

  end
  #
  # tests for aws
  context '.AWS' do

    it "Check Vagrantfile aws config import" do
      aws_config_file = '../aws-config.yml'
      awsConfigImport = Generator.awsProviderConfigImport(aws_config_file)
      Generator.awsProviderConfigImport(aws_config_file).should eq(awsConfigImport)
    end

    it "Check Vagrantfile aws provider config" do
      awsProviderConfig = Generator.awsProviderConfig
      Generator.awsProviderConfig.should eq(awsProviderConfig)
    end

    it "Check AWS VM definition" do
      aws_def = Generator.getAWSVmDef('../recipes/cookbooks/', 'node1', 'centos7', 'ec2-user', 't1.micro', './cnf', true)
      aws_def = Generator.getAWSVmDef('../recipes/cookbooks/', 'node1', 'centos7', 'ec2-user', 't1.micro', './cnf', true).should eq(aws_def)
    end

  end
  #
  # tests for libvirt
  context '.LIBVIRT' do

    it "Check Vagrantfile provider config" do
      $session = Session.new
      $session.nodesProvider = 'libvirt'
      providerConfig = Generator.providerConfig
      Generator.providerConfig.should eq(providerConfig)
    end

    it "Check Libvirt VM definition" do
      qemu_def = Generator.getQemuDef('../cookbooks/recipes/', 'galera0', 'galera0', 'centos_7_libvirt', './cnf', true)
      Generator.getQemuDef('../cookbooks/recipes/', 'galera0', 'galera0', 'centos_7_libvirt', './cnf', true).should eq(qemu_def)
    end

  end
  #
  # tests for docker
  context '.DOCKER' do

    it "Check Vagrantfile provider config" do
      $session = Session.new
      $session.nodesProvider = 'docker'
      providerConfig = Generator.providerConfig
      Generator.providerConfig.should eq(providerConfig)
    end

    it "Check Docker VM definition" do
      docker_def = Generator.getDockerDef('../cookbooks/recipes/', 'node0', './cnf', true)
      Generator.getDockerDef('../cookbooks/recipes/', 'node0', './cnf', true).should eq(docker_def)
    end

    it "copy docker files" do
      # Generator.copyDockerfiles(path, name, platform, platform_version)
    end

  end
  #
  # tests for vagrant roles
  context '.ROLES' do

    it "Check role file name" do
      roleFileName = Generator.roleFileName('.', 'node')
      Generator.roleFileName('.', 'node').should eq(roleFileName)
    end

    # TODO: Generator.getRoleDef(name, product, box)
    it "Check roles definition" do
      # Generator.getRoleDef(name, product, box)
    end

  end



end
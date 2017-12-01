require 'rspec'
require_relative '../spec_helper'
require_relative '../../core/generator'
require_relative '../../core/session'

describe "Generator" do

  # TODO
  it "Check node definition" do
    # Generator.nodeDefinition(node, boxes, path, cookbook_path)
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
      $mdbci_exec_dir = ENV['WORKSPACE']
      $session = Session.new
      $session.nodesProvider = 'virtualbox'
      providerConfig = Generator.providerConfig
      Generator.providerConfig.should eq(providerConfig)
    end

    it "Check VBOX vm definition" do
      vm_def = Generator.getVmDef('../cookbooks/recipes', 'node0', 'node0', 'ubuntu_trusty','true', '1024', './cnf', true)
      Generator.getVmDef('../cookbooks/recipes', 'node0', 'node0', 'ubuntu_trusty', 'true', '1024', './cnf', true).should eq(vm_def)
    end

  end
  #
  # tests for aws
  context '.AWS' do

    it 'Check Vagrantfile aws config import' do
      aws_config_file = '../aws-config.yml'
      aws_config_import = Generator.awsProviderConfigImport(aws_config_file)
      expect(Generator.awsProviderConfigImport(aws_config_file)).to eq(aws_config_import)
    end

    it 'Check Vagrantfile aws provider config' do
      pem_file_path = 'file.pem'
      keypair_name = 'keypair'
      aws_provider_config = Generator.awsProviderConfig(pem_file_path, keypair_name)
      expect(aws_provider_config).to include(pem_file_path)
      expect(aws_provider_config).to include(keypair_name)
    end

    it 'Check AWS VM definition' do
      aws_def = Generator.getAWSVmDef('../recipes/cookbooks/', 'node1', 'centos7',
                                      'ec2-user', 'true', 't1.micro', './cnf', true, 'test')
      expect(Generator.getAWSVmDef('../recipes/cookbooks/', 'node1', 'centos7',
                                   'ec2-user', 'true', 't1.micro', './cnf', true,
                                   'test')).to eq(aws_def)
    end

  end
  #
  # tests for libvirt
  context '.LIBVIRT' do

    it "Check Vagrantfile provider config" do
      $mdbci_exec_dir = ENV['WORKSPACE']
      $session = Session.new
      $session.nodesProvider = 'libvirt'
      providerConfig = Generator.providerConfig
      Generator.providerConfig.should eq(providerConfig)
    end

    it "Check Libvirt VM definition" do
      qemu_def = Generator.getQemuDef('../cookbooks/recipes/', ENV['WORKSPACE'], 'galera0', 'galera0', 'centos_7_libvirt', 'true', '1024', './cnf', true)
      Generator.getQemuDef('../cookbooks/recipes/', ENV['WORKSPACE'], 'galera0', 'galera0', 'centos_7_libvirt', 'true', '1024', './cnf', true).should eq(qemu_def)
    end

  end
  #
  # tests for docker
  context '.DOCKER' do

    it "Check Vagrantfile provider config" do
      $mdbci_exec_dir = ENV['WORKSPACE']
      $session = Session.new
      $session.nodesProvider = 'docker'
      providerConfig = Generator.providerConfig
      Generator.providerConfig.should eq(providerConfig)
    end

    it "Check Docker VM definition" do
      docker_def = Generator.getDockerDef('../cookbooks/recipes/', 'path', 'node0', 'true', './cnf', true, 'centos', '7', 'centos_7_libvirt')
      Generator.getDockerDef('../cookbooks/recipes/', 'path', 'node0', 'true', './cnf', true, 'centos', '7', 'centos_7_libvirt').should eq(docker_def)
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

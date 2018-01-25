require 'commands/generate_command'
require 'session'

describe "GenerateCommand" do

  # TODO
  it "Check node definition" do
    # GenerateCommand.nodeDefinition(node, boxes, path, cookbook_path)
  end

  # TODO
  it "Check generator" do
    # GenerateCommand.generate(path, config, boxes, override, provider)
  end

  #
  # tests for virtualbox
  context '.Vagrantfile' do

    it "Check Vagrantfile header" do
      vagrantFileHeader = GenerateCommand.vagrantFileHeader
      GenerateCommand.vagrantFileHeader.should eq(vagrantFileHeader)
    end

    it "Check Vagrantfile config header" do
      configHeader = GenerateCommand.vagrantConfigHeader
      GenerateCommand.vagrantConfigHeader.should eq(configHeader)
    end

    it "Check Vagrantfile config footer" do
      configFooter = GenerateCommand.vagrantConfigFooter
      GenerateCommand.vagrantConfigFooter.should eq(configFooter)
    end

    it "Check Vagrantfile footer" do
      vagrantFooter = GenerateCommand.vagrantFooter
      GenerateCommand.vagrantFooter.should eq(vagrantFooter)
    end

  end
  #
  # tests for virtualbox
  context '.VBOX' do

    it "Check Vagrantfile provider config" do
      $mdbci_exec_dir = File.absolute_path('.')
      $session = Session.new
      $session.nodesProvider = 'virtualbox'
      providerConfig = GenerateCommand.providerConfig
      GenerateCommand.providerConfig.should eq(providerConfig)
    end

    it "Check VBOX vm definition" do
      vm_def = GenerateCommand.getVmDef('../cookbooks/recipes', 'node0', 'node0', 'ubuntu_trusty','true', '1024', './cnf', true)
      GenerateCommand.getVmDef('../cookbooks/recipes', 'node0', 'node0', 'ubuntu_trusty', 'true', '1024', './cnf', true).should eq(vm_def)
    end

  end
  #
  # tests for aws
  context '.AWS' do

    it 'Check Vagrantfile aws config import' do
      aws_config_file = '../aws-config.yml'
      aws_config_import = GenerateCommand.awsProviderConfigImport(aws_config_file)
      expect(GenerateCommand.awsProviderConfigImport(aws_config_file)).to eq(aws_config_import)
    end

    it 'Check Vagrantfile aws provider config' do
      pem_file_path = 'file.pem'
      keypair_name = 'keypair'
      aws_provider_config = GenerateCommand.awsProviderConfig(pem_file_path, keypair_name)
      expect(aws_provider_config).to include(pem_file_path)
      expect(aws_provider_config).to include(keypair_name)
    end

    it 'Check AWS VM definition' do
      aws_def = GenerateCommand.getAWSVmDef('../recipes/cookbooks/', 'node1', 'centos7',
                                      'ec2-user', 'true', 't1.micro', './cnf', true, 'test')
      expect(GenerateCommand.getAWSVmDef('../recipes/cookbooks/', 'node1', 'centos7',
                                   'ec2-user', 'true', 't1.micro', './cnf', true,
                                   'test')).to eq(aws_def)
    end

  end
  #
  # tests for libvirt
  context '.LIBVIRT' do

    it "Check Vagrantfile provider config" do
      $mdbci_exec_dir = File.absolute_path('.')
      $session = Session.new
      $session.nodesProvider = 'libvirt'
      providerConfig = GenerateCommand.providerConfig
      GenerateCommand.providerConfig.should eq(providerConfig)
    end

    it "Check Libvirt VM definition" do
      qemu_def = GenerateCommand.getQemuDef('../cookbooks/recipes/', File.absolute_path('.'), 'galera0', 'galera0', 'centos_7_libvirt', 'true', '1024', './cnf', true)
      GenerateCommand.getQemuDef('../cookbooks/recipes/', File.absolute_path('.'), 'galera0', 'galera0', 'centos_7_libvirt', 'true', '1024', './cnf', true).should eq(qemu_def)
    end

  end
  #
  # tests for docker
  context '.DOCKER' do

    it "Check Vagrantfile provider config" do
      $mdbci_exec_dir = File.absolute_path('.')
      $session = Session.new
      $session.nodesProvider = 'docker'
      providerConfig = GenerateCommand.providerConfig
      GenerateCommand.providerConfig.should eq(providerConfig)
    end

    it "Check Docker VM definition" do
      docker_def = GenerateCommand.getDockerDef('../cookbooks/recipes/', 'path', 'node0', 'true', './cnf', true, 'centos', '7', 'centos_7_libvirt')
      GenerateCommand.getDockerDef('../cookbooks/recipes/', 'path', 'node0', 'true', './cnf', true, 'centos', '7', 'centos_7_libvirt').should eq(docker_def)
    end

    it "copy docker files" do
      # GenerateCommand.copyDockerfiles(path, name, platform, platform_version)
    end

  end
  #
  # tests for vagrant roles
  context '.ROLES' do

    it "Check role file name" do
      roleFileName = GenerateCommand.roleFileName('.', 'node')
      GenerateCommand.roleFileName('.', 'node').should eq(roleFileName)
    end

    # TODO: GenerateCommand.getRoleDef(name, product, box)
    it "Check roles definition" do
      # GenerateCommand.getRoleDef(name, product, box)
    end

  end

  context '.getVmDef' do
    it "should return string with '\tconfig.ssh.pty = true' in it" do
      GenerateCommand.getVmDef('TEST', 'TEST','TEST' , 'TEST', true, 'TEST', 'TEST', 'TEST').should include 'box.ssh.pty = true'
    end

    it "should return string without '\tconfig.ssh.pty = true' in it" do
      GenerateCommand.getVmDef('TEST', 'TEST','TEST' , 'TEST', false, 'TEST', 'TEST', 'TEST').should_not include 'box.ssh.pty = true'
    end
  end

  context '.getQemudef' do
    it "should return string with '\tconfig.ssh.pty = true' in it" do
      GenerateCommand.getQemuDef('TEST', 'TEST','TEST' , 'TEST', 'TEST', 'true', '1024', 'TEST', false).should include 'config.ssh.pty = true'
    end

    it "should return string with '\tconfig.ssh.pty = false' in it" do
      GenerateCommand.getQemuDef('TEST', 'TEST','TEST' , 'TEST', 'TEST', 'false', '1024', 'TEST', false).should include 'config.ssh.pty = false'
    end
  end

  context '.getDockerDef' do
    it "should return string with '\tconfig.ssh.pty = true' in it" do
      GenerateCommand.getDockerDef('TEST', 'TEST','true' , 'TEST', 'TEST', 'TEST', 'TEST', 'TEST', 'TEST').should_not include 'config.ssh.pty = true'
    end

    it "should return string without '\tconfig.ssh.pty = true' in it" do
      GenerateCommand.getDockerDef('TEST', 'TEST','false' , 'TEST', 'TEST', 'TEST', 'TEST', 'TEST', 'TEST').should_not include 'config.ssh.pty = true'
    end
  end

  context '.getAWSVmDef' do
    it "should return string without '\tconfig.ssh.pty = true' in it" do
      GenerateCommand.getAWSVmDef('TEST', 'TEST','TEST' , 'TEST', 'true', 'TEST', 'TEST', 'TEST', 'TEST').should include 'config.ssh.pty = true'
    end

    it "should return string without '\tconfig.ssh.pty = true' in it" do
      GenerateCommand.getAWSVmDef('TEST', 'TEST','TEST' , 'TEST', 'false', 'TEST', 'TEST', 'TEST', 'TEST').should_not include 'config.ssh.pty = true'
    end
  end

  context '.generateAwsTag' do
    it 'execute bash command without output' do
      tags = GenerateCommand.generateAwsTag({
                                        'hostname' => 'test',
                                        'username' => 'test',
                                        'full_config_path' => 'test'
                                      })
      tags.should eql "{ \"hostname\" => \"test\", \"username\" => \"test\", \"full_config_path\" => \"test\" }"
    end
  end
end

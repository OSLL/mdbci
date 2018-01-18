require 'commands/generator_command'
require 'session'

describe "Generator" do

  # TODO
  it "Check node definition" do
    # GeneratorCommand.nodeDefinition(node, boxes, path, cookbook_path)
  end

  # TODO
  it "Check generator" do
    # GeneratorCommand.generate(path, config, boxes, override, provider)
  end

  #
  # tests for virtualbox
  context '.Vagrantfile' do

    it "Check Vagrantfile header" do
      vagrantFileHeader = GeneratorCommand.vagrantFileHeader
      GeneratorCommand.vagrantFileHeader.should eq(vagrantFileHeader)
    end

    it "Check Vagrantfile config header" do
      configHeader = GeneratorCommand.vagrantConfigHeader
      GeneratorCommand.vagrantConfigHeader.should eq(configHeader)
    end

    it "Check Vagrantfile config footer" do
      configFooter = GeneratorCommand.vagrantConfigFooter
      GeneratorCommand.vagrantConfigFooter.should eq(configFooter)
    end

    it "Check Vagrantfile footer" do
      vagrantFooter = GeneratorCommand.vagrantFooter
      GeneratorCommand.vagrantFooter.should eq(vagrantFooter)
    end

  end
  #
  # tests for virtualbox
  context '.VBOX' do

    it "Check Vagrantfile provider config" do
      $mdbci_exec_dir = File.absolute_path('.')
      $session = Session.new
      $session.nodesProvider = 'virtualbox'
      providerConfig = GeneratorCommand.providerConfig
      GeneratorCommand.providerConfig.should eq(providerConfig)
    end

    it "Check VBOX vm definition" do
      vm_def = GeneratorCommand.getVmDef('../cookbooks/recipes', 'node0', 'node0', 'ubuntu_trusty','true', '1024', './cnf', true)
      GeneratorCommand.getVmDef('../cookbooks/recipes', 'node0', 'node0', 'ubuntu_trusty', 'true', '1024', './cnf', true).should eq(vm_def)
    end

  end
  #
  # tests for aws
  context '.AWS' do

    it 'Check Vagrantfile aws config import' do
      aws_config_file = '../aws-config.yml'
      aws_config_import = GeneratorCommand.awsProviderConfigImport(aws_config_file)
      expect(GeneratorCommand.awsProviderConfigImport(aws_config_file)).to eq(aws_config_import)
    end

    it 'Check Vagrantfile aws provider config' do
      pem_file_path = 'file.pem'
      keypair_name = 'keypair'
      aws_provider_config = GeneratorCommand.awsProviderConfig(pem_file_path, keypair_name)
      expect(aws_provider_config).to include(pem_file_path)
      expect(aws_provider_config).to include(keypair_name)
    end

    it 'Check AWS VM definition' do
      aws_def = GeneratorCommand.getAWSVmDef('../recipes/cookbooks/', 'node1', 'centos7',
                                      'ec2-user', 'true', 't1.micro', './cnf', true, 'test')
      expect(GeneratorCommand.getAWSVmDef('../recipes/cookbooks/', 'node1', 'centos7',
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
      providerConfig = GeneratorCommand.providerConfig
      GeneratorCommand.providerConfig.should eq(providerConfig)
    end

    it "Check Libvirt VM definition" do
      qemu_def = GeneratorCommand.getQemuDef('../cookbooks/recipes/', File.absolute_path('.'), 'galera0', 'galera0', 'centos_7_libvirt', 'true', '1024', './cnf', true)
      GeneratorCommand.getQemuDef('../cookbooks/recipes/', File.absolute_path('.'), 'galera0', 'galera0', 'centos_7_libvirt', 'true', '1024', './cnf', true).should eq(qemu_def)
    end

  end
  #
  # tests for docker
  context '.DOCKER' do

    it "Check Vagrantfile provider config" do
      $mdbci_exec_dir = File.absolute_path('.')
      $session = Session.new
      $session.nodesProvider = 'docker'
      providerConfig = GeneratorCommand.providerConfig
      GeneratorCommand.providerConfig.should eq(providerConfig)
    end

    it "Check Docker VM definition" do
      docker_def = GeneratorCommand.getDockerDef('../cookbooks/recipes/', 'path', 'node0', 'true', './cnf', true, 'centos', '7', 'centos_7_libvirt')
      GeneratorCommand.getDockerDef('../cookbooks/recipes/', 'path', 'node0', 'true', './cnf', true, 'centos', '7', 'centos_7_libvirt').should eq(docker_def)
    end

    it "copy docker files" do
      # GeneratorCommand.copyDockerfiles(path, name, platform, platform_version)
    end

  end
  #
  # tests for vagrant roles
  context '.ROLES' do

    it "Check role file name" do
      roleFileName = GeneratorCommand.roleFileName('.', 'node')
      GeneratorCommand.roleFileName('.', 'node').should eq(roleFileName)
    end

    # TODO: GeneratorCommand.getRoleDef(name, product, box)
    it "Check roles definition" do
      # GeneratorCommand.getRoleDef(name, product, box)
    end

  end

  context '.getVmDef' do
    it "should return string with '\tconfig.ssh.pty = true' in it" do
      GeneratorCommand.getVmDef('TEST', 'TEST','TEST' , 'TEST', 'true', 'TEST', 'TEST', 'TEST').should include 'config.ssh.pty = true'
    end

    it "should return string without '\tconfig.ssh.pty = true' in it" do
      GeneratorCommand.getVmDef('TEST', 'TEST','TEST' , 'TEST', 'false', 'TEST', 'TEST', 'TEST').should_not include 'config.ssh.pty = true'
    end
  end

  context '.getQemudef' do
    it "should return string with '\tconfig.ssh.pty = true' in it" do
      GeneratorCommand.getQemuDef('TEST', 'TEST','TEST' , 'TEST', 'TEST', 'true', '1024', 'TEST', false).should include 'config.ssh.pty = true'
    end

    it "should return string with '\tconfig.ssh.pty = false' in it" do
      GeneratorCommand.getQemuDef('TEST', 'TEST','TEST' , 'TEST', 'TEST', 'false', '1024', 'TEST', false).should include 'config.ssh.pty = false'
    end
  end

  context '.getDockerDef' do
    it "should return string with '\tconfig.ssh.pty = true' in it" do
      GeneratorCommand.getDockerDef('TEST', 'TEST','true' , 'TEST', 'TEST', 'TEST', 'TEST', 'TEST', 'TEST').should_not include 'config.ssh.pty = true'
    end

    it "should return string without '\tconfig.ssh.pty = true' in it" do
      GeneratorCommand.getDockerDef('TEST', 'TEST','false' , 'TEST', 'TEST', 'TEST', 'TEST', 'TEST', 'TEST').should_not include 'config.ssh.pty = true'
    end
  end

  context '.getAWSVmDef' do
    it "should return string without '\tconfig.ssh.pty = true' in it" do
      GeneratorCommand.getAWSVmDef('TEST', 'TEST','TEST' , 'TEST', 'true', 'TEST', 'TEST', 'TEST', 'TEST').should include 'config.ssh.pty = true'
    end

    it "should return string without '\tconfig.ssh.pty = true' in it" do
      GeneratorCommand.getAWSVmDef('TEST', 'TEST','TEST' , 'TEST', 'false', 'TEST', 'TEST', 'TEST', 'TEST').should_not include 'config.ssh.pty = true'
    end
  end

  context '.generateAwsTag' do
    it 'execute bash command without output' do
      tags = GeneratorCommand.generateAwsTag({
                                        'hostname' => 'test',
                                        'username' => 'test',
                                        'full_config_path' => 'test'
                                      })
      tags.should eql "{ \"hostname\" => \"test\", \"username\" => \"test\", \"full_config_path\" => \"test\" }"
    end
  end
end

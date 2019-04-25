require 'commands/generate_command'
require 'session'
require 'out'

describe "GenerateCommand" do
  before(:all) do
    $mdbci_exec_dir = '.'
    $session = Session.new
    $out = Out.new($session)
  end


  context '.AWS' do
    it 'Check Vagrantfile aws provider config' do
      pem_file_path = 'file.pem'
      keypair_name = 'keypair'
      aws_provider_config = GenerateVagrantConfigurationCommand.aws_provider_config(pem_file_path, keypair_name)
      expect(aws_provider_config).to include(pem_file_path)
      expect(aws_provider_config).to include(keypair_name)
    end
  end
  context '.get_virtualbox_definition' do
    it "should return string with '\tconfig.ssh.pty = true' in it" do
      GenerateVagrantConfigurationCommand.get_virtualbox_definition('TEST', 'TEST', 'TEST' , 'TEST', true, 'TEST', 'TEST', 'TEST').should include 'box.ssh.pty = true'
    end

    it "should return string without '\tconfig.ssh.pty = true' in it" do
      GenerateVagrantConfigurationCommand.get_virtualbox_definition('TEST', 'TEST', 'TEST' , 'TEST', false, 'TEST', 'TEST', 'TEST').should_not include 'box.ssh.pty = true'
    end
  end

  context '.get_libvirt_definition' do
    it "should return string with '\tconfig.ssh.pty = true' in it" do
      GenerateVagrantConfigurationCommand.get_libvirt_definition('TEST', 'TEST', 'TEST' , 'TEST', 'TEST', 'true', '1024', 'TEST', false).should include 'config.ssh.pty = true'
    end

    it "should return string with '\tconfig.ssh.pty = false' in it" do
      GenerateVagrantConfigurationCommand.get_libvirt_definition('TEST', 'TEST', 'TEST' , 'TEST', 'TEST', 'false', '1024', 'TEST', false).should include 'config.ssh.pty = false'
    end
  end

  context '.get_docker_definition' do
    it "should return string with '\tconfig.ssh.pty = true' in it" do
      GenerateVagrantConfigurationCommand.get_docker_definition('TEST', 'TEST', 'true' , 'TEST', 'TEST', 'TEST', 'TEST', 'TEST', 'TEST').should_not include 'config.ssh.pty = true'
    end

    it "should return string without '\tconfig.ssh.pty = true' in it" do
      GenerateVagrantConfigurationCommand.get_docker_definition('TEST', 'TEST', 'false' , 'TEST', 'TEST', 'TEST', 'TEST', 'TEST', 'TEST').should_not include 'config.ssh.pty = true'
    end
  end

  context '.get_aws_vms_definition' do
    it "should return string without '\tconfig.ssh.pty = true' in it" do
      GenerateVagrantConfigurationCommand.get_aws_vms_definition('TEST', 'TEST', 'TEST' , 'TEST', 'true', 'TEST', 'TEST', 'TEST', 'TEST').should include 'config.ssh.pty = true'
    end

    it "should return string without '\tconfig.ssh.pty = true' in it" do
      GenerateVagrantConfigurationCommand.get_aws_vms_definition('TEST', 'TEST', 'TEST' , 'TEST', 'false', 'TEST', 'TEST', 'TEST', 'TEST').should_not include 'config.ssh.pty = true'
    end
  end

  context '.generateAwsTag' do
    it 'execute bash command without output' do
      tags = GenerateVagrantConfigurationCommand.generate_aws_tag({
                                        'hostname' => 'test',
                                        'username' => 'test',
                                        'full_config_path' => 'test'
                                      })
      tags.should eql "{ \"hostname\" => \"test\", \"username\" => \"test\", \"full_config_path\" => \"test\" }"
    end
  end
end

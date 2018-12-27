# frozen_string_literal: true

require 'tmpdir'
require 'fileutils'
require 'stringio'
require 'models/configuration'

describe 'destroy command', :system do
  before(:example) do
    @test_dir = Dir.mktmpdir
  end

  after(:example) do
    FileUtils.rm_r @test_dir
  end

  context 'when do not given path to the configuration' do
    it 'should return an error code' do
      expect(mdbci_run_command('destroy')).not_to be_success
    end
  end

  context 'when given path without proper configuration' do
    it 'should return an error code' do
      expect(mdbci_run_command("destroy #{@test_dir}")).not_to be_success
    end
  end

  context 'when configuration was not created' do
    it 'should remove all configuration files' do
      template = 'centos_7_libvirt_plain'
      config = mdbci_create_configuration(@test_dir, template)
      expect(mdbci_run_command("destroy #{config}")).to be_success
      expect(Dir.exist?(config)).to be_falsy
      expect(File.exist?("#{@test_dir}/#{template}.json")).to be_falsey
    end
  end

  context 'when configuration is running' do
    it 'should stop vms and remove all files' do
      config = mdbci_create_configuration(@test_dir, 'centos_7_libvirt_plain')
      mdbci_check_command("up #{config}")
      expect(mdbci_run_command("destroy #{config}")).to be_success
      expect(run_command('virsh list --all').messages).not_to include('centos_7_libvirt_plain')
      expect(Dir.exist?(config)).to be_falsy
      expect(File.exist?("#{config}#{Configuration::NETWORK_FILE_SUFFIX}")).to be_falsy
    end
  end

  context 'when configuration is stopped' do
    it 'should remove all files' do
      config = mdbci_create_configuration(@test_dir, 'centos_7_libvirt_plain')
      mdbci_check_command("up #{config}")
      run_command_in_dir('vagrant halt', config)
      expect(mdbci_run_command("destroy #{config}")).to be_success
      expect(Dir.exist?(config)).to be_falsy
    end
  end

  context 'when destorying a single node' do
    it 'should not destroy the configuration files' do
      config = mdbci_create_configuration(@test_dir, 'centos_7_libvirt_plain')
      expect(mdbci_run_command("destroy #{config}/node")).to be_success
      expect(Dir.exist?(config)).to be_truthy
    end
  end

  context 'when passing --keep-template parameter' do
    it 'should keep the template file' do
      template = 'centos_7_libvirt_plain'
      config = mdbci_create_configuration(@test_dir, template)
      expect(mdbci_run_command("destroy --keep-template #{config}")).to be_success
      expect(Dir.exist?(config)).to be_falsy
      expect(File.exist?("#{@test_dir}/#{template}.json")).to be_truthy
    end
  end

  context 'when destroying whole aws configuration' do
    it 'should destroy the aws keypair too' do
      template = 'suse_13_aws_plain'
      config = mdbci_create_configuration(@test_dir, template)
      keypair = File.read("#{config}/#{Configuration::AWS_KEYPAIR_NAME}").chomp
      expect(mdbci_run_command("destroy #{config}")).to be_success
      result = run_command("aws ec2 describe-key-pairs --key-names '#{keypair}'")
      expect(result).not_to be_success
    end
  end

  context 'when vagrant was unable to destroy libvirt machine' do
    it 'should destroy it manually' do
      template = 'centos_7_libvirt_plain'
      config = mdbci_create_configuration(@test_dir, template)
      mdbci_check_command("up #{config}")
      FileUtils.rm_f("#{config}/Vagrantfile")
      FileUtils.touch("#{config}/Vagrantfile")
      mdbci_check_command("destroy #{config}")
      libvirt_domain = "#{template}_node"
      result = run_command("virsh domstats #{libvirt_domain}")
      expect(result).not_to be_success
    end
  end

  context 'when vagrant was unable to destroy VirtualBox machine' do
    it 'should destroy it manually' do
      template = 'centos_6_vbox_plain'
      config = mdbci_create_configuration(@test_dir, template)
      mdbci_check_command("up #{config}")
      FileUtils.rm_f("#{config}/Vagrantfile")
      FileUtils.touch("#{config}/Vagrantfile")
      mdbci_check_command("destroy #{config}")
      vbox_name = "#{template}_node"
      result = run_command("VBoxManage showvminfo #{vbox_name}")
      expect(result).not_to be_success
    end
  end

  context 'when call with --list option' do
    it 'should display virtual machines list' do
      template = 'centos_7_libvirt_plain'
      config = mdbci_create_configuration(@test_dir, template)
      mdbci_check_command("up #{config}")
      destroy_list = mdbci_check_command('destroy --list')
      mdbci_check_command("destroy #{config}")
      libvirt_domain = "#{template}_node"
      expect(destroy_list.to_s).to include(libvirt_domain)
    end
  end

  context 'when call with --node-name option' do
    it 'should destroy virtual machine by name without configuration' do
      template = 'centos_7_libvirt_plain'
      config = mdbci_create_configuration(@test_dir, template)
      mdbci_check_command("up #{config}")
      FileUtils.rm_f("#{config}/Vagrantfile")
      FileUtils.touch("#{config}/Vagrantfile")
      libvirt_domain = "#{template}_node"
      mdbci_check_command("destroy --node-name #{libvirt_domain}", stdin_data: 'y')
      result = run_command("virsh domstats #{libvirt_domain}")
      expect(result).not_to be_success
    end
  end
end

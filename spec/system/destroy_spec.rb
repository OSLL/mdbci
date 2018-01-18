# frozen_string_literal: true

require 'tmpdir'
require 'fileutils'
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

  context 'when given path to the proper configuration' do
    context 'when configuration was not created' do
      it 'should remove all configuration files' do
        template = 'centos_7_libvirt_plain'
        config = mdbci_create_configuration(@test_dir, template)
        expect(mdbci_run_command("destroy #{config}")).to be_success
        expect(Dir.exist?(config)).to be_falsy
        expect(File.exist?("#{@test_dir}/{template}.json")).to be_falsey
      end
    end

    context 'when configuration is running' do
      it 'should stop vms and remove all files' do
        config = mdbci_create_configuration(@test_dir, 'centos_7_libvirt_plain')
        mdbci_check_command("up #{config}")
        expect(mdbci_run_command("destroy #{config}")).to be_success
        expect(run_command('virsh list').messages).not_to include('centos_7_libvirt_plain')
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
  end
end

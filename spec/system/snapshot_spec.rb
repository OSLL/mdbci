# frozen_string_literal: true

require 'tmpdir'
require 'fileutils'

describe 'snaphot command', :system do
  before(:example) do
    @configs_to_destroy = []
    @test_dir = Dir.mktmpdir
  end

  after(:example) do
    @configs_to_destroy.each do |config|
      run_command_in_dir('vagrant destroy -f', config)
    end
    FileUtils.rm_r @test_dir
  end

  context 'revert subcommand' do
    context 'when trying to revert not-created configuration' do
      it 'should return an error code' do
        config = mdbci_create_configuration(@test_dir, 'centos_7_libvirt_plain')
        @configs_to_destroy.push(config)
        expect(mdbci_run_command("snapshot revert --path-to-nodes #{config} --snapshot-name test")).not_to be_success
      end
    end

    context 'when trying to revert non-running configuration' do
      it 'should return an error code' do
        config = mdbci_create_configuration(@test_dir, 'centos_7_libvirt_plain')
        @configs_to_destroy.push(config)
        run_command_in_dir('vagrant up', config)
        mdbci_check_command("snapshot take --path-to-nodes #{config} --snapshot-name test")
        run_command_in_dir('vagrant halt', config)
        expect(mdbci_run_command("snapshot revert --path-to-nodes #{config} --snapshot-name test")).not_to be_success
      end
    end

    context 'when trying to revert destroyed configuration' do
      it 'should return an error code' do
        config = mdbci_create_configuration(@test_dir, 'centos_7_libvirt_plain')
        @configs_to_destroy.push(config)
        run_command_in_dir('vagrant up', config)
        mdbci_check_command("snapshot take --path-to-nodes #{config} --snapshot-name test")
        run_command_in_dir('vagrant destroy -f', config)
        expect(mdbci_run_command("snapshot revert --path-to-nodes #{config} --snapshot-name test")).not_to be_success
      end
    end
  end
end

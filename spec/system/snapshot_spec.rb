# frozen_string_literal: true

require 'tmpdir'
require 'fileutils'

describe 'snaphot command', :system do
  before(:example) do
    @test_dir = Dir.mktmpdir
  end

  after(:example) do
    FileUtils.rm_r @test_dir
  end

  context 'revert subcommand' do
    context 'when trying to revert non-created configuration' do
      it 'should return error code' do
        config = mdbci_create_configuration(@test_dir, 'centos_7_libvirt_plain')
        expect(mdbci_command("snapshot revert --path-to-nodes #{config} --snapshot unknown")).not_to be_success
      end
    end
  end
end

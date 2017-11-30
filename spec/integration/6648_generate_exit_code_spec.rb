require 'fileutils'
require 'rspec'
require_relative '../spec_helper'

def test_command (template_path, config_name)
  template_path_parameter = "--template #{template_path}"
  return "./mdbci --override #{template_path_parameter} generate #{config_name}"
end

describe 'test_spec' do

  after :each do
    FileUtils.rm_rf('default') if Dir.exists? 'default'
  end

  execute_shell_commands_and_test_exit_code ([
      {shell_command: test_command('', ''), exit_code: 1},
      {shell_command: test_command('spec/configs/template/centos_6_vbox_mariadb_10.0.json', ''), exit_code: 0},
      {shell_command: test_command('spec/configs/template/centos_6_vbox_mariadb_10.0.json', 'default'), exit_code: 0}
  ])
end
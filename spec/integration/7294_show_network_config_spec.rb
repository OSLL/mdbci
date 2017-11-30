require 'rspec'
require_relative '../spec_helper'

describe 'test_spec' do
  execute_shell_commands_and_test_exit_code ([
    {shell_command: "./mdbci show network_config #{ENV['mdbci_param_conf_docker']}", exit_code: 0},
    {shell_command: './mdbci show network_config', exit_code: 1},
    {shell_command: './mdbci show network_config NOT_EXIST', exit_code: 1}
  ])
end

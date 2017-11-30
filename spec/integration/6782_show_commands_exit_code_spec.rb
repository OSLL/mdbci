require 'rspec'
require_relative '../spec_helper'

describe 'test_spec' do
  execute_shell_commands_and_test_exit_code ([
    {shell_command: './mdbci show platforms', exit_code: 0},
    {shell_command: './mdbci show boxes', exit_code: 1},
    {shell_command: './mdbci show boxes ubuntu', exit_code: 1}
  ])
end

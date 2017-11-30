require 'rspec'
require_relative '../spec_helper'

describe 'test_spec' do
  execute_shell_commands_and_test_exit_code ([
    {shell_command: 'echo *', exit_code: 0}, # succes
    {shell_command: 'cp \'ll\'', exit_code: 1} # failure
  ])
end

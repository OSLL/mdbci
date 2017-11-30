require 'spec_helper'

describe 'show command' do
  execute_shell_commands_and_test_exit_code(
    [
      { shell_command: './mdbci show', exit_code: 0 },
      { shell_command: './mdbci show help', exit_code: 0 },
      { shell_command: './mdbci show UNREAL', exit_code: 2 },
      { shell_command: './mdbci show box', exit_code: 2 },
      { shell_command: './mdbci show boxes', exit_code: 1 }
    ])
end

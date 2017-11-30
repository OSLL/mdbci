require 'spec_helper'

describe 'show boxinfo command' do
  execute_shell_commands_and_test_exit_code ([
    {shell_command: './mdbci show boxinfo --box-name ubuntu_trusty_vbox --field platform', exit_code: 0},
    {shell_command: './mdbci show boxinfo --box-name ubuntu_trusty_vbox', exit_code: 0},
    {shell_command: './mdbci show boxinfo --box-name ubuntu_trusty_vbox --field', exit_code: 1},
    {shell_command: './mdbci show boxinfo --box-name ubuntu_trusty_vbox --field WRONG', exit_code: 1},
    {shell_command: './mdbci show boxinfo --box-name WRONG --field platform', exit_code: 1},
    {shell_command: './mdbci show boxinfo --box-name WRONG --field WRONG', exit_code: 1},
    {shell_command: './mdbci show boxinfo --box-name WRONG', exit_code: 1}
  ])
end

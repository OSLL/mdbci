require 'rspec'
require_relative '../spec_helper'

describe 'test_spec' do
  executeShellCommandsAndTestExitCode ([
    {'shell_command'=>'./mdbci show boxinfo --box-name ubuntu_trusty_vbox --field platform', 'expectation'=>0},
    {'shell_command'=>'./mdbci show boxinfo --box-name ubuntu_trusty_vbox', 'expectation'=>0},
    {'shell_command'=>'./mdbci show boxinfo --box-name ubuntu_trusty_vbox --field', 'expectation'=>1},
    {'shell_command'=>'./mdbci show boxinfo --box-name ubuntu_trusty_vbox --field WRONG', 'expectation'=>1},
    {'shell_command'=>'./mdbci show boxinfo --box-name WRONG --field platform', 'expectation'=>1},
    {'shell_command'=>'./mdbci show boxinfo --box-name WRONG --field WRONG', 'expectation'=>1},
    {'shell_command'=>'./mdbci show boxinfo --box-name WRONG', 'expectation'=>1}
  ])
end

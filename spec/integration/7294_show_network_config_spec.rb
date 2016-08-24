require 'rspec'
require_relative '../spec_helper'

describe 'test_spec' do
  executeShellCommandsAndTestExitCode ([
    {'shell_command'=>"./mdbci show network_config #{ENV['mdbci_param_conf_docker']}", 'expectation'=>0},
    {'shell_command'=> './mdbci show network_config', 'expectation'=>1},
    {'shell_command'=> './mdbci show network_config NOT_EXIST', 'expectation'=>1}
  ])
end

require 'rspec'
require_relative '../spec_helper'


describe 'test_spec' do
  executeShellCommandsAndTestExitCode ([
      {'shell_command'=>"./mdbci show box #{ENV['mdbci_param_conf_docker']}/node1", 'expectation'=>0},
      {'shell_command'=>"./mdbci show box #{ENV['mdbci_param_conf_docker']}", 'expectation'=>1},
      {'shell_command'=>'./mdbci show box WRONG', 'expectation'=>1},
      {'shell_command'=>'./mdbci show box ' + ENV['mdbci_param_conf_docker'] + '/WRONG', 'expectation'=>1},
  ])
end


require 'rspec'
require_relative '../spec_helper'

describe 'test_spec' do
  executeShellCommandsAndTestExitCode ([
    {'shell_command'=>"./mdbci show network_config #{ENV["pathToNetworkConfig"]}", 'expectation'=>0}, 
    {'shell_command'=>"./mdbci show network_config", 'expectation'=>1},
    {'shell_command'=>"./mdbci show network_config #{ENV["pathToInvalidNamedNetworkConfig"]}", 'expectation'=>1}
  ])
end

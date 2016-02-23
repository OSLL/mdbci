require 'rspec'
require 'spec_helper'

describe 'test_spec' do
  executeShellCommandsAndTestExitCode ([
    {'shell_command'=>'./mdbci show boxes', 'expectation'=>0}, # succes
    {'shell_command'=>'./mdbci show platforms', 'expectation'=>} # failure
  ])
end

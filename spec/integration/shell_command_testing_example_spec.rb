require 'rspec'
require_relative '../spec_helper'

describe 'test_spec' do
  executeShellCommandsAndTestExitCode ([
    {'shell_command'=>'echo *', 'expectation'=>0}, # succes
    {'shell_command'=>'cp \'ll\'', 'expectation'=>1} # failure
  ])
end

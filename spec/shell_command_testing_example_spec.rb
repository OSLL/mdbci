require 'rspec'
require 'spec_helper'
require_relative '../core/session'
require_relative '../core/repo_manager'

describe 'test_spec' do
  executeShellCommandsAndTestExitCode ([
    {'shell_command'=>'echo *', 'expectation'=>0}, # succes
    {'shell_command'=>'cp \'ll\'', 'expectation'=>1} # failure
  ])
end

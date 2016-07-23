require 'rspec'
require_relative '../spec_helper'


describe 'test_spec' do
  executeShellCommandsAndTestExitCode ([
      {'shell_command'=>'./mdbci show box ' + ENV['pathToConfigNode'], 'expectation'=>0},
      {'shell_command'=>'./mdbci show box ' + ENV['pathToConfig'], 'expectation'=>1},
      {'shell_command'=>'./mdbci show box WRONG', 'expectation'=>1},
      {'shell_command'=>'./mdbci show box ' + ENV['pathToConfig'] + '/WRONG', 'expectation'=>1},
  ])
end


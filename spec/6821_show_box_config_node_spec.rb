require 'rspec'
require 'spec_helper'

require_relative '../core/session'
require_relative '../core/node_product'
require_relative '../core/out'
require_relative '../core/repo_manager'
require_relative '../core/exception_handler'

describe 'Session' do

  before :all do
    $out = Out.new
    $session = Session.new
    $session.isSilent = true
    $session.mdbciDir = Dir.pwd
    $exception_handler = ExceptionHandler.new
    boxesPath = './BOXES'
    $session.boxes = BoxesManager.new boxesPath
  end

  it '#getBoxByGeneratedConfig returns boxes for generated configuration' do
    $session.boxes.getBoxByGeneratedConfig(ENV['pathToConfigNode']).should eq({"provider"=>"virtualbox","box"=>"bento/centos-6.7","platform"=>"centos","platform_version"=>"6"})
  end

  it '#getBoxByGeneratedConfig returns boxes for generated configuration' do
    $session.boxes.getBoxByGeneratedConfig(ENV['pathToConfig']).should eq([{"provider"=>"virtualbox","box"=>"bento/centos-6.7","platform"=>"centos","platform_version"=>"6"}])
  end

  it '#getBoxByGeneratedConfig returns boxes for generated configuration' do
    lambda{$session.boxes.getBoxByGeneratedConfig('WRONG')}.should raise_error 'Path to generated nodes configurations is wrong'
  end

  it '#getBoxByGeneratedConfig returns boxes for generated configuration' do
    boxesPath = 'WRONG'
    $session.boxes = BoxesManager.new boxesPath
    lambda{$session.boxes.getBoxByGeneratedConfig('WRONG')}.should raise_error 'Path to generated nodes configurations is wrong'
  end


end

describe 'test_spec' do
  executeShellCommandsAndTestExitCode ([
      {'shell_command'=>'./mdbci show box ' + ENV['pathToConfigNode'], 'expectation'=>0},
      {'shell_command'=>'./mdbci show box ' + ENV['pathToConfig'], 'expectation'=>0},
      {'shell_command'=>'./mdbci show box WRONG', 'expectation'=>1},
  ])
end
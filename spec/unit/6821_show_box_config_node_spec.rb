require 'rspec'

require_relative '../spec_helper'
require_relative '../../core/session'
require_relative '../../core/node_product'
require_relative '../../core/out'
require_relative '../../core/services/repo_manager'
require_relative '../../core/exception_handler'

describe 'Session' do

  DOCKER_CONF = ENV['mdbci_param_conf_docker']

  before :all do
    $mdbci_exec_dir = File.absolute_path('.')
    $out = Out.new
    $session = Session.new
    $session.isSilent = true
    $session.mdbciDir = Dir.pwd
    $exception_handler = ExceptionHandler.new
    boxesPath = './BOXES'
    $session.boxes = BoxesManager.new boxesPath
  end

  it '#getBoxByGeneratedConfig returns boxes for generated configuration for node1' do
    result =  $session.boxes.getBoxByGeneratedConfig("#{DOCKER_CONF}/node1")
    result.should_not eql nil
  end

  it '#getBoxByGeneratedConfig returns boxes for generated configuration' do
    result =  $session.boxes.getBoxByGeneratedConfig(DOCKER_CONF)
    result.each do |hash|
      hash.should_not eql nil
    end
  end

  it '#getBoxByGeneratedConfig raises boxes for generated configuration' do
    lambda{$session.boxes.getBoxByGeneratedConfig('WRONG')}.should raise_error 'Path to generated nodes configurations is wrong'
  end

  it '#getBoxByGeneratedConfig raises boxes for generated configuration' do
    boxesPath = 'WRONG'
    $session.boxes = BoxesManager.new boxesPath
    lambda{$session.boxes.getBoxByGeneratedConfig('WRONG')}.should raise_error 'Path to generated nodes configurations is wrong'
  end


end


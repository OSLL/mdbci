require 'rspec'

require_relative '../spec_helper'
require_relative '../../core/session'
require_relative '../../core/node_product'
require_relative '../../core/out'
require_relative '../../core/repo_manager'
require_relative '../../core/exception_handler'

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
    result =  $session.boxes.getBoxByGeneratedConfig(ENV['pathToConfigNode'])
    result.each do |key,value|
      case key      
      when 'provider'      
        value.should match(/.+/)
      when 'box'
        value.should match(/\w+\S*/) #word.not_whitespace
      when 'platform_varsion'
        value.should match(/\d+\.?\d*/) #digit.dot.digit
      else
        value.should match(/.+/)
      end
    end
  end

  it '#getBoxByGeneratedConfig returns boxes for generated configuration' do
    result =  $session.boxes.getBoxByGeneratedConfig(ENV['pathToConfig'])
    result.each do |hash|
      hash.each do |key,value|
        case key
        when 'provider'
          value.should match(/.+/)
        when 'box'
          value.should match(/\w+\S*/)
        when 'platform_varsion'
          value.should match(/\d+\.?\d*/) #digit.dot.digit
        else
          value.should match(/.+/)
        end
      end
    end
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


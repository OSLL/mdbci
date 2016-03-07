require 'rspec'
require 'spec_helper'

require_relative '../core/session'
require_relative '../core/boxes_manager'
require_relative '../core/exception_handler'
require_relative '../core/out'

describe 'BoxesManager' do
  it 'lookup and add boxes' do
    $out = Out.new
    $session = Session.new
    $session.isSilent = true
    $session.mdbciDir = Dir.pwd
    $exception_handler = ExceptionHandler.new
    boxesPath = './BOXES'
    $session.boxes = BoxesManager.new boxesPath
    $session.boxes.boxesManager.size().should eq(48)
  end
end

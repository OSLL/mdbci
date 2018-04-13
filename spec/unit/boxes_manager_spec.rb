require 'rspec'
require_relative '../spec_helper'

require_relative '../../core/session'
require_relative '../../core/boxes_manager'
require_relative '../../core/exception_handler'
require_relative '../../core/out'

describe 'BoxesManager' do
  it 'lookup and add boxes' do
    $mdbci_exec_dir = File.absolute_path('.')
    $session = Session.new
    $out = Out.new($session)
    $session.isSilent = true
    $session.mdbciDir = Dir.pwd
    $exception_handler = ExceptionHandler.new
    boxesPath = './BOXES'
    $session.boxes = BoxesManager.new boxesPath
    $session.boxes.boxesManager.size().should_not eq(0)
  end
end

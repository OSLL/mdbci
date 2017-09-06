require 'rspec'
require_relative '../spec_helper'

require_relative '../../core/out'
require_relative '../../core/exception_handler'
require_relative '../../core/boxes_manager'
require_relative '../../core/session'

describe 'Session' do

  before :all do
    $mdbci_exec_dir = ENV['WORKSPACE']
    $out = Out.new
    $session = Session.new
    $session.isSilent = true
    $session.mdbciDir = Dir.pwd
    $exception_handler = ExceptionHandler.new
    boxesPath = './BOXES'
    $session.boxes = BoxesManager.new boxesPath
  end

  it '#findBoxField should return json with machine config' do
    $session.findBoxField('ubuntu_trusty_vbox', nil).should(eql('{"provider":"virtualbox","box":"bento/ubuntu-14.04","box_version":"2.2.3","platform":"ubuntu","platform_version":"trusty"}'))
  end

  it '#findBoxField should return platforn field from machine config' do
    $session.findBoxField('ubuntu_trusty_vbox', 'platform').should(eql('ubuntu'))
  end

  it '#findBoxField should raise error "Box WRONG is not found"' do
    lambda {$session.findBoxField('WRONG', 'platform')}.should raise_error(RuntimeError, 'Box WRONG is not found')
  end

  it '#findBoxField should raise error "ERROR:  Box ubuntu_trusty_vbox does not have WRONG key"' do
    lambda {$session.findBoxField('ubuntu_trusty_vbox', 'WRONG')}.should raise_error(RuntimeError, 'Box ubuntu_trusty_vbox does not have WRONG key')
  end

end

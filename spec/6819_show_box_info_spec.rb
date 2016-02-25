require 'rspec'
require 'spec_helper'

require_relative '../core/out'
require_relative '../core/exception_handler'
require_relative '../core/boxes_manager'
require_relative '../core/session'

describe 'test_spec' do
  executeShellCommandsAndTestExitCode ([
    {'shell_command'=>'./mdbci show boxinfo --box-name ubuntu_trusty_vbox --field platform', 'expectation'=>0},
    {'shell_command'=>'./mdbci show boxinfo --box-name ubuntu_trusty_vbox', 'expectation'=>0},
    {'shell_command'=>'./mdbci show boxinfo --box-name ubuntu_trusty_vbox --field', 'expectation'=>1},
    {'shell_command'=>'./mdbci show boxinfo --box-name ubuntu_trusty_vbox --field WRONG', 'expectation'=>1},
    {'shell_command'=>'./mdbci show boxinfo --box-name WRONG --field platform', 'expectation'=>1},
    {'shell_command'=>'./mdbci show boxinfo --box-name WRONG --field WRONG', 'expectation'=>1},
    {'shell_command'=>'./mdbci show boxinfo --box-name WRONG', 'expectation'=>1}
  ])
end

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

  it '#findBoxField should return json with machine config' do
    $session.field = nil
    $session.boxName = 'ubuntu_trusty_vbox'
    $session.findBoxField.should(eql('{"provider":"virtualbox","box":"http://localhost/test/Projects/OSLL/mdbci_main/testLibvirt/test.box","platform":"ubuntu","platform_version":"trusty"}'))
  end

  it '#findBoxField should return platforn field from machine config' do
    $session.field = 'platform'
    $session.boxName = 'ubuntu_trusty_vbox'
    $session.findBoxField.should(eql('ubuntu'))
  end

  it '#findBoxField should raise error "Box WRONG is not found"' do
    $session.field = 'platform'
    $session.boxName = 'WRONG'
    lambda {$session.findBoxField}.should raise_error(RuntimeError, 'ERROR:  Box WRONG is not found')
  end

  it '#findBoxField should raise error "ERROR:  Box ubuntu_trusty_vbox does not have WRONG key"' do
    $session.field = 'WRONG'
    $session.boxName = 'ubuntu_trusty_vbox'
    lambda {$session.findBoxField}.should raise_error(RuntimeError, 'ERROR:  Box ubuntu_trusty_vbox does not have WRONG key')
  end

end

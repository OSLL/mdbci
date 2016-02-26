require 'rspec'
require 'spec_helper'
require_relative '../core/out'
require_relative '../core/exception_handler'
require_relative '../core/boxes_manager'
require_relative '../core/session'

PLATFORM = %w(ubuntu centos debian rhel sles suse fedora opensuse rhel_ppc64 rhel_ppc64be sles_ppc64 ubuntu_ppc64)

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

  it '#getPlatfroms returns array of platforms' do
    $session.getPlatfroms.should eq(PLATFORM)
  end

  it '#getPlatfroms should rise error, because boxes are not found' do
    boxesPath = 'WRONG'
    $session.boxes = BoxesManager.new boxesPath
    lambda {$session.getPlatfroms}.should raise_error 'Boxes are not found'
  end

end

describe 'test_spec' do
  executeShellCommandsAndTestExitCode ([
      {'shell_command'=>'./mdbci show platforms', 'expectation'=>0},
  ])
end

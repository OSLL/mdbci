require 'rspec'
require 'spec_helper'
require_relative '../core/out'
require_relative '../core/exception_handler'
require_relative '../core/boxes_manager'
require_relative '../core/session'

describe 'Session' do

  before :all do
    $out = Out.new
    $session = Session.new
    $session.isSilent = true
    $session.mdbciDir = Dir.pwd
    $exception_handler = ExceptionHandler.new
    boxesPath = './BOXES'
    $session.boxes = BoxesManager.new boxesPath
    reposPath = './repo.d'
    $session.repos = RepoManager.new reposPath
  end

  it '#setup should exit with zero exit code when parameter \'boxes\' is defined' do
    #$session.setup('boxes').should(eql(0))
  end

  it '#setup should exit with non-zero exit code when parameter is wrong or shell command failed' do
    $session.setup('').should(eql(1))
  end

end

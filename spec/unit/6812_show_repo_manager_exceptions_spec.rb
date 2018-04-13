require 'rspec'

require_relative '../spec_helper'
require_relative '../../core/session'
require_relative '../../core/network'
require_relative '../../core/exception_handler'
require_relative '../../core/repo_manager'
require_relative '../../core/boxes_manager'

describe 'RepoManager' do

  before :all do
    $mdbci_exec_dir = File.absolute_path('.')
    $session = Session.new
    $out = Out.new($session)
    $session.isSilent = true
    $session.mdbciDir = Dir.pwd
    $exception_handler = ExceptionHandler.new
    boxesPath = './BOXES'
    $session.boxes = BoxesManager.new boxesPath
    reposPath = './repo.d'
    $session.repos = RepoManager.new reposPath
  end

  it '#lookup should raise error' do
    lambda {RepoManager.new 'WRONG'}.should raise_error 'Repositories was not found'
  end

  it '#getRepo should raise error' do
    lambda {$session.repos.getRepo 'WRONG'}.should raise_error 'Repository for key WRONG was not found'
  end
end

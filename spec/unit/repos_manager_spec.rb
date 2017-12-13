require 'rspec'
require_relative '../spec_helper'
require_relative '../../core/session'
require_relative '../../core/repo_manager'
require_relative '../../core/boxes_manager'
require_relative '../../core/exception_handler'

describe 'RepoManager' do
  context '.repos' do
    it "Check repos loading..." do
      $mdbci_exec_dir = File.absolute_path('.')
      $out = Out.new
      $session = Session.new
      $session.isSilent = true
      $session.mdbciDir = Dir.pwd
      $exception_handler = ExceptionHandler.new
      boxesPath = './BOXES'
      $session.boxes = BoxesManager.new boxesPath
      reposPath = './repo.d'
      $session.repos = RepoManager.new reposPath
      $session.repos.repos.size().should eq(752)
    end
  end
end
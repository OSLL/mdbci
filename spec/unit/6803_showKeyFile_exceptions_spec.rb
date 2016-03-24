require 'rspec'

require_relative '../spec_helper'
require_relative '../../core/session'
require_relative '../../core/network'
require_relative '../../core/exception_handler'
require_relative '../../core/repo_manager'
require_relative '../../core/boxes_manager'

describe 'Network' do

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

  it '#showKeyFile should raise exception' do
    lambda {Network.showKeyFile(nil)}.should raise_error 'Configuration name is required';
  end

  it '#showKeyFile should raise exception' do
    lambda {Network.showKeyFile('WRONG')}.should raise_error 'Configuration with such name does not exists';
  end

  it '#showKeyFile should raise exception' do
    lambda {Network.showKeyFile(ENV['pathToVboxFolder'] + '/WRONG')}.should raise_error(/Command.*exit with non-zero exit code.*/);
  end

end

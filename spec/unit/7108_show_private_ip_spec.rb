require 'rspec'
require_relative '../spec_helper'

require_relative '../../core/session'
require_relative '../../core/node_product'
require_relative '../../core/out'
require_relative '../../core/repo_manager'
require_relative '../../core/exception_handler'
require_relative '../../core/network'

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
    $session.awsConfigFile='aws-config.yml'

  end

  it 'show private IP should return IP and Node' do
    Network.private_ip(ENV['configPath']).should eq(0)
  end

 end
require 'rspec'
require 'spec_helper'
require_relative '../core/session'
require_relative '../core/node_product'
require_relative '../core/out'
require_relative '../core/repo_manager'
require_relative '../core/exception_handler'

describe 'Session' do

  '''
    RSpec matchers:

    expect()
    .should == ""
    .should == false
    .should be_false
    .should be_true
    .should be < 1
    .should_not == 5
    hungry? return true|false == should be_hungry
  '''

  context '.configurationFiles' do

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

    it "Check aws config loading..." do

      session = Session.new
      session.awsConfigFile='aws-config.yml'

      awsConfig = YAML.load_file(session.awsConfigFile)['aws']
      #out.out 'Found aws: ' + awsConfig.size().to_s

      # boxes is not empty
      awsConfig.size().should_not eq(0)
      awsConfig.size().should eq(9)

    end

    it "Check template loading..." do

      session = Session.new
      session.configFile='confs/galera-cnf-template.json'

      nodes = JSON.parse(IO.read(session.configFile))
      #out.out 'Found boxes: ' + boxes.size().to_s

      # boxes is not empty
      nodes.size().should_not eq(0)
      nodes.size().should eq(7)

    end

  end



end
require 'rspec'
require 'spec_helper'
require_relative '../core/session'
require_relative '../core/out'

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

    it "Check boxes loading..." do
      #pending # useful for Debugging

      session = Session.new
      #out = Out.new

      session.configFile='instance.json'
      session.boxesFile='boxes.json'
      session.awsConfigFile='aws-config.yml'

      boxes = JSON.parse(IO.read(session.boxesFile))
      #out.out 'Found boxes: ' + boxes.size().to_s

      # boxes is not empty
      boxes.size().should_not eq(0)
      boxes.size().should eq(32)

    end

    it "Check aws config loading..." do

      session = Session.new
      session.awsConfigFile='aws-config.yml'

      awsConfig = YAML.load_file(session.awsConfigFile)['aws']
      #out.out 'Found aws: ' + awsConfig.size().to_s

      # boxes is not empty
      awsConfig.size().should_not eq(0)
      awsConfig.size().should eq(8)

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
require 'rspec'
require 'spec_helper'
require 'json'
require_relative '../core/out'
require_relative '../core/exception_handler'
require_relative '../core/boxes_manager'
require_relative '../core/session'

BOX = {
    "provider"=>"aws",
    "ami"=>"ami-b1443fc6",
    "user"=>"ubuntu",
    "default_instance_type"=>"m3.medium",
    "platform"=>"ubuntu",
    "platform_version"=>"vivid"
}

JSON_BOX = BOX.to_json + "\n"

describe 'BoxesManager' do

  before :all do
    $out = Out.new
    $session = Session.new
    $session.isSilent = true
    $session.mdbciDir = Dir.pwd
    $exception_handler = ExceptionHandler.new
    boxesPath = './BOXES'
    $session.boxes = BoxesManager.new boxesPath
    reposPath = './repo.d'
  end

  # Before all tests must be generated configurations
  # vagrant machine must be running
  # for mdbci node must be created appropriate mdbci_template file and
  # must be prepared box with IP and keyfile location that is targeting real running machine
  # that can be accessed through ssh

  it '#getBoxByConfig return json with box definition' do
    $session.boxes.getBoxByConfig(ENV['configPath'], ENV['nodeName']).should(eql(BOX))
  end

  it '#getBoxByConfig return nil for wrong configPath' do
    lambda {$session.boxes.getBoxByConfig('WRONG', ENV['nodeName'])}
        .should(raise_error("Wrong config path or json implementation for WRONG"))
  end

  it '#getBoxByConfig return nil for wrong nodeName' do
    lambda {$session.boxes.getBoxByConfig(ENV['configPath'], 'WRONG')}
        .should(raise_error("Node WRONG is not found in confs/mdbci_up_aws_test_config.json"))
  end

  it '#showBoxByConfig output json with box definition to stdout' do
    lambda {$session.showBoxByConfig(ENV['configPath'], ENV['nodeName'])}.should output(JSON_BOX).to_stdout
  end

  it '#showBoxByConfig return 0' do
    lambda {$session.showBoxByConfig(ENV['configPath'], ENV['nodeName'])}.eql?(0)
  end

  it '#showBoxByConfig return 1' do
    lambda {$session.showBoxByConfig('WRONG', 'WRONG')}.eql?(1)
  end


end

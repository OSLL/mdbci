require 'rspec'
require 'json'

require_relative '../spec_helper'
require_relative '../../core/out'
require_relative '../../core/exception_handler'
require_relative '../../core/boxes_manager'
require_relative '../../core/session'

BOX_CONFIG = {
    "provider"=>"libvirt",
    "box"=>"baremettle/debian-7.5",
    "platform"=>"debian",
    "platform_version"=>"wheezy"
}

CONFIG = File.read('spec/configs/generated_config/6818_search_box_name_by_config/template')

NODE = 'node_000'

JSON_BOX = BOX_CONFIG.to_json + "\n"

describe 'BoxesManager' do

  before :all do
    $mdbci_exec_dir = File.absolute_path('.')
    $out = Out.new
    $session = Session.new
    $session.isSilent = true
    $session.mdbciDir = Dir.pwd
    $exception_handler = ExceptionHandler.new
    boxesPath = './BOXES'
    $session.boxes = BoxesManager.new boxesPath
    reposPath = './repo.d'
  end

  it '#getBoxByConfig return json with box definition' do
    $session.boxes.getBoxByConfig(CONFIG, NODE).should(eql(BOX_CONFIG))
  end

  it '#getBoxByConfig return nil for wrong configPath' do
    lambda {$session.boxes.getBoxByConfig('WRONG', NODE)}
        .should(raise_error("Wrong config path or json implementation for WRONG"))
  end

  it '#getBoxByConfig return nil for wrong nodeName' do
    lambda {$session.boxes.getBoxByConfig(CONFIG, 'WRONG')}.should raise_error /Node WRONG is not found in .*/
  end

end

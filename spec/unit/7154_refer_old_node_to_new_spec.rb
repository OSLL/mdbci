require 'rspec'
require 'fileutils'

require_relative '../spec_helper'
require_relative '../../core/clone'


PATH_TO_TEMPLATE = 'spec/test_machine_configurations/7154_refer_old_node_to_new.json'
PATH_TO_COPIED_TEMPLATE = 'spec/test_machine_configurations/7154_refer_old_node_to_new_copy.json'
NODE0 = 'node0'
NODE1 = 'node1'
NEW_BOX0 = 'NEW_BOX0'
NEW_BOX1 = 'NEW_BOX1'
BOX = 'box'

RES1 = JSON.parse(<<EOF
{
  "cookbook_path": "../recipes/cookbooks/",
  "node0": {
    "hostname": "node0",
    "box": "NEW_BOX0"
  },
  "node1": {
    "hostname": "node1",
    "box": "BOX2"
  }
}
EOF
)

RES2 = JSON.parse(<<EOF
{
  "cookbook_path": "../recipes/cookbooks/",
  "node0": {
    "hostname": "node0",
    "box": "NEW_BOX0"
  },
  "node1": {
    "hostname": "node1",
    "box": "NEW_BOX1"
  }
}
EOF
)

describe 'clone.rb' do

  before :all do
    $mdbci_exec_dir = File.absolute_path('.')
    $out = Out.new
    $session = Session.new
    FileUtils.cp PATH_TO_TEMPLATE, PATH_TO_COPIED_TEMPLATE
  end

  after :all do
    FileUtils.rm PATH_TO_COPIED_TEMPLATE
  end

  it '#change_box_in_docker_template will change box in copied config' do
    Clone.new.change_box_in_docker_template(PATH_TO_COPIED_TEMPLATE, NODE0, NEW_BOX0)
    copied_template = JSON.parse(File.read(PATH_TO_COPIED_TEMPLATE))
    copied_template.should eql RES1
  end

  it '#change_box_in_docker_template will change box in copied config' do
    Clone.new.change_box_in_docker_template(PATH_TO_COPIED_TEMPLATE, NODE1, NEW_BOX1)
    copied_template = JSON.parse(File.read(PATH_TO_COPIED_TEMPLATE))
    copied_template.should eql RES2
  end

end

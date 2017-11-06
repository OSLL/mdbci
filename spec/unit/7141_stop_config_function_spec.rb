require 'rspec'
require_relative '../spec_helper'
require_relative '../../core/out'
require_relative '../../core/session'
require_relative '../../core/helper'

node_name = 'node0'

def start_config(config_name)
  root_directory = Dir.pwd
  Dir.chdir config_name
  execute_bash("vagrant up --provider docker")
  Dir.chdir root_directory
end

describe 'clone.rb' do

  before :all do
    $mdbci_exec_dir = ENV['WORKSPACE']
    $out = Out.new
    $session = Session.new
    $session.isSilent = false
    start_config ENV['path_to_nodes_docker']
  end

  after :each do
    start_config ENV['path_to_nodes_docker']
  end

  it '#stop_config' do
    stop_config(ENV['path_to_nodes_docker'], ENV['node_name'])
    is_config_running(ENV['path_to_nodes_docker']).should eql false
  end

  it '#stop_config' do
    stop_config(ENV['path_to_nodes_docker'])
    is_config_running(ENV['path_to_nodes_docker']).should eql false
  end

end

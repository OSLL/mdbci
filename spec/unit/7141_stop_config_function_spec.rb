require 'rspec'
require 'fileutils'
require_relative '../spec_helper'
require_relative '../../core/out'
require_relative '../../core/session'
require_relative '../../core/helper'

def start_config(config_name)
  root_directory = Dir.pwd
  Dir.chdir config_name
  execute_bash("vagrant up --provider libvirt")
  Dir.chdir root_directory
end

vagrantfile = <<EOF
Vagrant.configure(2) do |config|
	config.vm.define "node0" do |node0|
		node0.vm.box = "baremettle/debian-7.5"
	end
end
EOF

config = File.basename __FILE__
template_path = "confs/#{config}.json"
node_name = 'node0'
provider = 'libvirt'

describe 'clone.rb' do

  before :all do
    $out = Out.new
    $session = Session.new
    $session.isSilent = false
    FileUtils.mkdir_p config
    File.open("#{config}/Vagrantfile", 'w') do |file|
      file.write vagrantfile
    end
    File.open("#{config}/provider", 'w') do |file|
      file.write provider
    end
    File.open("#{config}/template", 'w') do |file|
      file.write template_path
    end
  end

  before :each do
    start_config config
  end

  it '#stop_config_node' do
    stop_config_node(config, node_name)
    is_config_running(config).should eql false
  end

  it '#stop_config' do
    stop_config config
    is_config_running(config).should eql false
  end

end

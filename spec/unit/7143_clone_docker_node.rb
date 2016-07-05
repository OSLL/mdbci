require 'rspec'
require_relative '../spec_helper'
require_relative '../../core/out'
require_relative '../../core/session'
require_relative '../../core/clone'

describe nil do

  before :all do
    $out = Out.new
    $session = Session.new
  end

  it 'create clone of docker container to new image' do
    image_name = create_docker_node_clone(ENV['path_to_nodes'], ENV['node_name'], ENV['path_to_new_config_directory'])
    `docker images | grep #{image_name}`
    $?.exitstatus.should eql 0
    `docker rmi #{image_name}`
  end

end
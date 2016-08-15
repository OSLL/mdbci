require 'rspec'
require_relative '../../core/helper'

describe nil do

  it 'checking for parametrized testing docker machine status to be running' do
    is_config_running(ENV['mdbci_param_conf_docker']).should eql true
  end

  it 'checking for parametrized testing libvirt machine status to be running' do
    is_config_created(ENV['mdbci_param_conf_libvirt']).should eql false
  end

  it 'checking for parametrized testing docker for ppc machine status to be running' do
    is_config_created('mdbci_param_test_clone_docker_for_ppc').should eql false
  end

  it 'checking for parametrized testing ppc from docker machine status to be running' do
    is_config_created(ENV['mdbci_param_conf_ppc']).should eql false
  end

end

require 'rspec'
require_relative '../../core/helper'

CONFIG_PREFIX = 'mdbci_param_test'
CLONED_CONFIG_INFIX = 'clone'

DOCKER = 'docker'
LIBVIRT = 'libvirt'
DOCKER_FOR_PPC = 'docker_for_ppc'
PPC_FROM_DOCKER = 'ppc_from_docker'

CLONED_CONFIG_DOCKER = "#{CONFIG_PREFIX}_#{CLONED_CONFIG_INFIX}_#{DOCKER}"
CLONED_CONFIG_LIBVIRT = "#{CONFIG_PREFIX}_#{CLONED_CONFIG_INFIX}_#{LIBVIRT}"
CLONED_CONFIG_DOCKER_FOR_PPC = "#{CONFIG_PREFIX}_#{CLONED_CONFIG_INFIX}_#{DOCKER_FOR_PPC}"
CLONED_CONFIG_PPC_FROM_DOCKER = "#{CONFIG_PREFIX}_#{CLONED_CONFIG_INFIX}_#{PPC_FROM_DOCKER}"

describe nil do

  it 'checking for parametrized testing docker machine status to be running' do
    is_config_running(CLONED_CONFIG_DOCKER).should eql true
  end

  it 'checking for parametrized testing libvirt machine status to be running' do
    is_config_created(CLONED_CONFIG_LIBVIRT).should eql false
  end

  it 'checking for parametrized testing docker for ppc machine status to be running' do
    is_config_created(CLONED_CONFIG_DOCKER_FOR_PPC).should eql false
  end

  it 'checking for parametrized testing ppc from docker machine status to be running' do
    is_config_created(CLONED_CONFIG_PPC_FROM_DOCKER).should eql false
  end

end

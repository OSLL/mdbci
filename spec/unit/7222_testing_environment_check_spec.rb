require 'rspec'
require_relative '../../core/helper'

CONFIG_PREFIX = 'mdbci_param_test'
CLONED_CONFIG_INFIX = 'clone'

DOCKER = 'docker'
LIBVIRT = 'libvirt'
VIRTUALBOX = 'virtualbox'
AWS = 'aws'
DOCKER_FOR_PPC = 'docker_for_ppc'
PPC_FROM_DOCKER = 'ppc_from_docker'

CONFIG_DOCKER = "#{CONFIG_PREFIX}_#{DOCKER}"
CONFIG_LIBVIRT = "#{CONFIG_PREFIX}_#{LIBVIRT}"
CONFIG_DOCKER_FOR_PPC = "#{CONFIG_PREFIX}_#{DOCKER_FOR_PPC}"

CLONED_CONFIG_DOCKER = "#{CONFIG_PREFIX}_#{CLONED_CONFIG_INFIX}_#{DOCKER}"
CLONED_CONFIG_LIBVIRT = "#{CONFIG_PREFIX}_#{CLONED_CONFIG_INFIX}_#{LIBVIRT}"
CLONED_CONFIG_DOCKER_FOR_PPC = "#{CONFIG_PREFIX}_#{CLONED_CONFIG_INFIX}_#{DOCKER_FOR_PPC}"
CLONED_CONFIG_PPC_FROM_DOCKER = "#{CONFIG_PREFIX}_#{CLONED_CONFIG_INFIX}_#{PPC_FROM_DOCKER}"

describe nil do

  it 'checking for parametrized testing origin docker machine status to be running' do
    is_config_running(CONFIG_DOCKER)
  end

  it 'checking for parametrized testing origin libvirt machine status to be running' do
    is_config_running(CONFIG_LIBVIRT)
  end

  it 'checking for parametrized testing origin docker for ppc machine status to be running' do
    is_config_running(CONFIG_DOCKER_FOR_PPC)
  end

  it 'checking for parametrized testing docker machine status to be running' do
    is_config_running(CLONED_CONFIG_DOCKER)
  end

  it 'checking for parametrized testing libvirt machine status to be running' do
    is_config_running(CLONED_CONFIG_LIBVIRT)
  end

  it 'checking for parametrized testing docker for ppc machine status to be running' do
    is_config_running(CLONED_CONFIG_DOCKER_FOR_PPC)
  end

  it 'checking for parametrized testing ppc from docker machine status to be running' do
    Dir.exist?(CLONED_CONFIG_PPC_FROM_DOCKER)
  end

end

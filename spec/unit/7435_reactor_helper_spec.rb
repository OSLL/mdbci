require 'rspec'
require_relative '../../core/helper'

LIBVIRT_CONFIG = ENV['param_test_conf_libvirt']
NODE = 'node1'

MACHINE_STATUSES = <<EOF
node1                     running (libvirt)
node2                     running (libvirt)
node3                     running (libvirt)
EOF

describe 'helper.rb' do

  it '#within_directory_content with valid commands, without exceptions' do
    output = within_directory_content(LIBVIRT_CONFIG){
      execute_bash('vagrant status')
    }
    expect(output).to(include(MACHINE_STATUSES))
  end

  it '#within_directory_content with invalid commands, with exceptions' do
    expect(within_directory_content(LIBVIRT_CONFIG){
      raise 'ERROR'
    }).to raise_error 'ERROR'
  end

  it '#within_directory_content with invalid commands, with custom exceptions' do
    expect(within_directory_content(LIBVIRT_CONFIG, 'CUSTOM ERROR'){
      raise 'ERROR'
    }).to raise_error 'CUSTOM ERROR, ERROR'
  end

  it '#stop_config_node' do
    stop_config_node(LIBVIRT_CONFIG, NODE)
    expect(is_config_node_stopped(LIBVIRT_CONFIG, NODE)).to(be(true))
  end

  it '#stop_config' do
    stop_config(LIBVIRT_CONFIG)
    expect(is_config_stopped(LIBVIRT_CONFIG)).to(be(true))
  end

  it '#start_config_node' do
    start_config_node(LIBVIRT_CONFIG, NODE)
    expect(is_config_node_running(LIBVIRT_CONFIG, NODE)).to(be(true))
  end

  it '#start_config' do
    start_config(LIBVIRT_CONFIG, true, true)
    expect(is_config_running(LIBVIRT_CONFIG)).to(be(true))
  end

  it '#suspend_config_node' do
    suspend_config_node(LIBVIRT_CONFIG, NODE)
    expect(is_config_node_paused(LIBVIRT_CONFIG, NODE)).to(be(true))
  end

  it '#resume_config_node' do
    resume_config_node(LIBVIRT_CONFIG, NODE)
    expect(is_config_node_running(LIBVIRT_CONFIG, NODE)).to(be(true))
  end

  it '#get_status' do
    expect(get_config_node_status(LIBVIRT_CONFIG, NODE)).to(be('RUNNING'))
  end

end

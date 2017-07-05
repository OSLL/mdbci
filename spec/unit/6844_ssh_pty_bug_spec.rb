require 'rspec'
require_relative '../spec_helper'
require_relative '../../core/generator'

describe 'Generator' do

  # Before all tests must be generated configurations
  # vagrant machine must be running
  # for mdbci node must be created appropriate mdbci_template file and
  # must be prepared box with IP and keyfile location that is targeting real running machine
  # that can be accessed through ssh
  before :all do
    $mdbci_exec_dir = ENV['WORKSPACE']
    $session = Session.new
    $session.ipv6 = false
  end

  it "#getVmDef should return string with '\tconfig.ssh.pty = true' in it" do
    Generator.getVmDef('TEST', 'TEST','TEST' , 'TEST', 'true', 'TEST', 'TEST', 'TEST').should include 'config.ssh.pty = true'
  end

  it "#getVmDef should return string without '\tconfig.ssh.pty = true' in it" do
    Generator.getVmDef('TEST', 'TEST','TEST' , 'TEST', 'false', 'TEST', 'TEST', 'TEST').should_not include 'config.ssh.pty = true'
  end

  it "#getQemuDef should return string with '\tconfig.ssh.pty = true' in it" do
    Generator.getQemuDef('TEST', 'TEST','TEST' , 'TEST', 'TEST', 'true', '1024', 'TEST', false).should include 'config.ssh.pty = true'
  end

  it "#getQemuDef should return string with '\tconfig.ssh.pty = false' in it" do
    Generator.getQemuDef('TEST', 'TEST','TEST' , 'TEST', 'TEST', 'false', '1024', 'TEST', false).should include 'config.ssh.pty = false'
  end
  it "#getDockerDef should return string with '\tconfig.ssh.pty = true' in it" do
    Generator.getDockerDef('TEST', 'TEST','true' , 'TEST', 'TEST', 'TEST', 'TEST', 'TEST', 'TEST').should_not include 'config.ssh.pty = true'
  end

  it "#getDockerDef should return string without '\tconfig.ssh.pty = true' in it" do
    Generator.getDockerDef('TEST', 'TEST','false' , 'TEST', 'TEST', 'TEST', 'TEST', 'TEST', 'TEST').should_not include 'config.ssh.pty = true'
  end

  it "#getAWSVmDef should return string without '\tconfig.ssh.pty = true' in it" do
    Generator.getAWSVmDef('TEST', 'TEST','TEST' , 'TEST', 'true', 'TEST', 'TEST', 'TEST', 'TEST').should include 'config.ssh.pty = true'
  end

  it "#getAWSVmDef should return string without '\tconfig.ssh.pty = true' in it" do
    Generator.getAWSVmDef('TEST', 'TEST','TEST' , 'TEST', 'false', 'TEST', 'TEST', 'TEST', 'TEST').should_not include 'config.ssh.pty = true'
  end

end

require 'rspec'
require_relative '../spec_helper'
require_relative '../../core/out'
require_relative '../../core/exception_handler'
require_relative '../../core/session'

describe 'Session' do

  before :all do
    $out = Out.new
    $session = Session.new
  end


  it '#clone should exit with zero code for libvirt provider' do
    $session.clone(ENV['pathToConfigToMDBCILibvirtProviderNode'].to_s, ENV['pathToConfigToMDBCILibvirtProviderNode'].to_s).should(eql(0))
  end


  it '#clone should exit with zero code for docker provider' do
    $session.clone(ENV['pathToConfigToMDBCIDockerProviderNode'].to_s, ENV['pathToConfigToMDBCIDockerProviderNode'].to_s).should(eql(0))
  end


  it '#clone should exit with non-zero code for another provider ' do
    $session.clone(ENV['pathToConfigToMDBCIBadNode'].to_s, ENV['pathToConfigToMDBCIBadNode'].to_s).should(eql(1))
  end

end

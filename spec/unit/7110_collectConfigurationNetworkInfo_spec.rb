require 'rspec'
require_relative '../spec_helper'
require_relative '../../core/session'
require_relative '../../core/node_product'
require_relative '../../core/out'
require_relative '../../core/repo_manager'
require_relative '../../core/exception_handler'
require_relative '../../core/network'

describe 'Network' do

  before :all do
    $out = Out.new
    $session = Session.new
    $session.isSilent = true
    $session.mdbciDir = Dir.pwd
    $exception_handler = ExceptionHandler.new
    boxesPath = './BOXES'
    $session.boxes = BoxesManager.new boxesPath
    reposPath = './repo.d'
    $session.configFile='instance.json'
    $session.awsConfigFile='aws-config.yml'
    $session.repos = RepoManager.new reposPath
    $session.checkConfig
    $session.loadCollections
  end

  # Before all tests must be generated configurations
  # vagrant machine must be running
  # for mdbci node must be created appropriate mdbci_template file and
  # must be prepared box with IP and keyfile location that is targeting real running machine
  # that can be accessed through ssh
  
  file_network_config = "#{ENV['configPath']}_network_config"
  nil_file_network_config = "_network_config"
  wrong_file_network_config = "WRONG_PATH_network_config"
  
  it 'collectConfigurationNetworkInfo should raise error: wrong path' do
    lambda{collectConfigurationNetworkInfo(ENV['stoppedConfigPath'])}.should raise_error("some error")
  end

  it 'collectConfigurationNetworkInfo should return correct Hash' do
    result = collectConfigurationNetworkInfo(ENV['configPath'])
    result.each do |key,value|
      case key
      when /.*_network/
        value.should match(/.+\..+\..+\..+/)
      when /.*_keyfile/
        value.should match(/\/.+/)
      when /.*_private_ip/
        value.should match(/.+\..+\..+\..+/)
      when /.*_whoami/
        value.should match(/.+/)
      when /.*_hostname/
        value.should match(/.+/)
      end
    end
  end

  it 'printConfigurationNetworkInfoToFile should raise error: error_name' do
    lambda{printConfigurationNetworkInfoToFile(nil)}.should raise_error(/.* template not found/)
  end

  it 'printConfigurationNetworkInfoToFile should raise error: error_name' do
    lambda{printConfigurationNetworkInfoToFile("WRONG_PATH")}.should raise_error(/.* template not found/)
  end

  it 'printConfigurationNetworkInfoToFile should create file in repo dir' do
    printConfigurationNetworkInfoToFile(ENV['configPath'])
    expect(File).to exist(file_network_config)
  end

  after :all do
    FileUtils.rm_rf file_network_config
    FileUtils.rm_rf nil_file_network_config
    FileUtils.rm_rf wrong_file_network_config
  end
 end

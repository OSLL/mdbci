require 'rspec'
require_relative '../spec_helper'
require_relative '../../core/out'
require_relative '../../core/exception_handler'
require_relative '../../core/boxes_manager'
require_relative '../../core/session'
require_relative '../../core/network'

getDefaultRecipeTemplate = <<EOF
\ttest.vm.provision "chef_solo" do |chef|
\t\tchef.cookbooks_path = "test"
\t\tchef.add_recipe "packages"
\tend
EOF

describe 'Generator' do

  before :all do
    $mdbci_exec_dir = ENV['WORKSPACE']
    $session = Session.new
    $session.ipv6 = false
  end

  it '#getDefaultRecipe returns default chef recipe for machine without product' do
    Generator.getDefaultRecipe('test', 'test').should eql getDefaultRecipeTemplate
  end

  it '#getVmDef returns config default recipe for machine without product' do
    Generator.getVmDef('test', 'test', 'test', 'test', 'test', 'test', 'test', false).should include getDefaultRecipeTemplate
  end

  it '#getQemuDef returns config default recipe for machine without product' do
    Generator.getQemuDef('TEST', 'TEST','TEST' , 'TEST', 'TEST', 'false', '1024', 'TEST', false).should include getDefaultRecipeTemplate
  end

  it '#getDockerDef returns config default recipe for machine without product' do
    Generator.getDockerDef('test', 'test', 'test', 'test', 'test', false, 'test', 'test', 'test').should include getDefaultRecipeTemplate
  end

  it '#getAwsDef returns config default recipe for machine without product' do
    Generator.getAWSVmDef('test', 'test', 'test', 'test', 'test', 'test', 'test', false, 'test').should include getDefaultRecipeTemplate
  end

  it '#getVmDef returns config default recipe for machine without product' do
    Generator.getVmDef('test', 'test', 'test', 'test', 'test', 'test', 'test', true).should_not include getDefaultRecipeTemplate
  end

  it '#getQemuDef returns config default recipe for machine without product' do
    Generator.getQemuDef('TEST', 'TEST','TEST' , 'TEST', 'TEST', 'false', '1024', 'TEST', true).should_not include getDefaultRecipeTemplate
  end

  it '#getDockerDef returns config default recipe for machine without product' do
    Generator.getDockerDef('test', 'test', 'test', 'test', 'test', true, 'test', 'test', 'test').should_not include getDefaultRecipeTemplate
  end

  it '#getAwsDef returns config default recipe for machine without product' do
    Generator.getAWSVmDef('test', 'test', 'test', 'test', 'test', 'test', 'test', true, 'test').should_not include getDefaultRecipeTemplate
  end
end
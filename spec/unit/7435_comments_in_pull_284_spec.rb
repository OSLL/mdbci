require 'rspec'
require_relative '../spec_helper'

require_relative '../../core/helper.rb'

describe 'core_helper.rb' do
  it '#in_dir should execute block in specified directory' do
    output = in_dir('spec') do
      execute_bash('pwd')
    end
    output.should eql "#{Dir.pwd}/spec\n"
  end



end
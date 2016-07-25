require 'rspec'
require 'fileutils'
require_relative '../spec_helper'
require_relative '../../core/session'
require_relative '../../core/generator'

RES = "{ \"hostname\" => \"test\", \"username\" => \"test\", \"full_config_path\" => \"test\" }"
describe nil do

  it 'execute bash command without output' do
    tags = Generator.generateAwsTag({
                              'hostname' => 'test',
                              'username' => 'test',
                              'full_config_path' => 'test'
                          })
    tags.should eql RES
  end

end
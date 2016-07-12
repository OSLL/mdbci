require 'rspec'
require_relative '../spec_helper'
require_relative '../../core/out'
require_relative '../../core/exception_handler'
require_relative '../../core/clone'


describe 'Clone' do

  it '#clone should exit with non-zero code if path to old config is not existing' do
    $clone.clone(ENV['pathToOldNotExistingConfig'].to_s, ENV['pathToValidNewConfig']).should(eql(1))
  end

  it '#clone should exit with non-zero code if nodes in the old config are not valid' do
    $clone.clone(ENV['pathToOldValidConfigWithoutValidNode'].to_s, ENV['pathToValidNewConfig']).should(eql(1))
  end

  it '#clone should exit with non-zero code if new path exists' do
    $clone.clone(ENV['pathToOldValidConfig'], ENV['pathToNotValidNewConfig']).should(eql(1))
  end

  it '#clone should exit with zero code if path to old config is valid, nodes in it are valid and new config path is not exists' do
    $clone.clone(ENV['pathToOldValidConfig'], ENV['pathToValidNewConfig']).should(eql(1))
  end

end

require 'rspec'
require_relative '../spec_helper'
require_relative '../../core/out'
require_relative '../../core/exception_handler'
require_relative '../../core/clone'


PATH_TO_OLD_NOT_EXISTING_CONFIG = "/pathToOldNotExistingConfig"
PATH_TO_VALID_NEW_CONFIG = "/pathToValidNewConfig"
PATH_TO_EMPTY_FOLDER = "/test_empty_folder"


describe 'Clone' do

  it '#clone should exit with non-zero code if path to old config is not existing' do
    lambda{ copyOldConfigDirectoryToNew(PATH_TO_OLD_NOT_EXISTING_CONFIG, PATH_TO_VALID_NEW_CONFIG) }.should  raise_error(RuntimeError, "Old config directory /pathToOldNotExistingConfig not found")

  end

  it '#clone should exit with non-zero code if nodes in old config are not existing' do
    lambda{ copyOldConfigDirectoryToNew(PATH_TO_EMPTY_FOLDER, PATH_TO_VALID_NEW_CONFIG) }.should raise_error(RuntimeError, "In old config directory /test_empty_folder nodes are not found")
  end

end

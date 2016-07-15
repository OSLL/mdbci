require 'rspec'
require_relative '../../core/clone'
require 'fileutils'

OLD_NOT_EXISTING_PATH = "pathToOldNotExistingConfig"
VALID_NEW_PATH = "spec/pathToValidNewConfig"
EMPTY_FOLDER = "spec/unit/test_empty_folder"
VALID_OLD_PATH = "spec/test_machine"
EXISTING_NEW_PATH = "spec/unit/test_empty_folder"


describe 'Clone' do

  it '#clone should exit with non-zero code if path to old config is not existing' do
    lambda{ copyOldConfigDirectoryToNew(OLD_NOT_EXISTING_PATH, VALID_NEW_PATH) }.should  raise_error(RuntimeError, "Old config directory pathToOldNotExistingConfig not found")
  end

  it '#clone should exit with non-zero code if nodes in old config are not existing' do
    FileUtils.mkdir(EMPTY_FOLDER)
    lambda{ copyOldConfigDirectoryToNew(EMPTY_FOLDER, VALID_NEW_PATH) }.should raise_error(RuntimeError, "In old config directory spec/unit/test_empty_folder nodes are not found")
    FileUtils.rm_rf(EMPTY_FOLDER)
  end

  it '#clone should exit with non-zero code if new folder is existing' do
    lambda{ copyOldConfigDirectoryToNew(VALID_OLD_PATH, EXISTING_NEW_PATH) }.should raise_error(RuntimeError, "New config directory spec/unit/test_empty_folder is existing")
  end

  it '#clone should copying all directories and subdirectories' do
    copyOldConfigDirectoryToNew(VALID_OLD_PATH, VALID_NEW_PATH)
    FileUtils.rm_rf(VALID_NEW_PATH)
  end

end

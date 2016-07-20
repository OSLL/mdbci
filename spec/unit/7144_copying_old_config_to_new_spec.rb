require 'rspec'
require_relative '../../core/clone'
require 'fileutils'

OLD_NOT_EXISTING_PATH = 'pathToOldNotExistingConfig'
VALID_NEW_PATH = 'spec/pathToValidNewConfig'
EMPTY_FOLDER = 'spec/unit/test_empty_folder'
VALID_OLD_PATH = 'spec/test_machine_configurations/7144_test_machine'
EXISTING_NEW_PATH = 'spec/unit/test_empty_folder'


describe 'Clone' do

  before :all do
    $out = Out.new
    $session = Session.new
  end

  it '#clone should exit with non-zero code if path to old config is not existing' do
    lambda{ copy_old_config_to_new(OLD_NOT_EXISTING_PATH, VALID_NEW_PATH) }.should  raise_error(RuntimeError, 'pathToOldNotExistingConfig: old config is not fully created')
  end

  it '#clone should exit with non-zero code if nodes in old config are not existing' do
    FileUtils.mkdir(EMPTY_FOLDER)
    lambda{ copy_old_config_to_new(EMPTY_FOLDER, VALID_NEW_PATH) }.should raise_error(RuntimeError, 'spec/unit/test_empty_folder: old config is not fully created')
    FileUtils.rm_rf(EMPTY_FOLDER)
  end

  it '#clone should exit with non-zero code if new folder is existing' do
    FileUtils.mkdir(EXISTING_NEW_PATH)
    lambda{ copy_old_config_to_new(VALID_OLD_PATH, EXISTING_NEW_PATH) }.should raise_error(RuntimeError, 'spec/unit/test_empty_folder: new config directory already exists (remove it and try again)')
    FileUtils.rm_rf(EXISTING_NEW_PATH)
  end

  it '#clone should copying all directories and subdirectories' do
    copy_old_config_to_new(VALID_OLD_PATH, VALID_NEW_PATH)
    FileUtils.rm_rf(VALID_NEW_PATH)
  end

end

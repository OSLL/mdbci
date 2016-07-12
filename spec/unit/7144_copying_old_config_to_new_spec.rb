require 'rspec'
require_relative '../spec_helper'
require_relative '../../core/out'
require_relative '../../core/exception_handler'
require_relative '../../core/clone'


PATH_TO_OLD_NOT_EXISTING_CONFIG = '/pathToOldNotExistingConfig'
PATH_TO_VALIDD_NEW_CONFIG = '/pathToValidNewConfig'



describe 'Clone' do

  it '#clone should exit with non-zero code if path to old config is not existing' do
    copyOldConfigDirectoryToNew('/pathToOldNotExistingConfig', 'pathToValidNewConfig').should(eql(1))
  end

end

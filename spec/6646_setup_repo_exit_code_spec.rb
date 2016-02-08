require 'rspec'
require 'spec_helper'

def test_command (product, product_version, config_path)
  return "./mdbci setup_repo --product #{product} --product-version #{product_version} #{config_path}"
end


describe 'test_spec' do
  executeShellCommandsAndTestExitCode ([
    {'shell_command'=>test_command('mariadb', '10.0', ENV['pathToConfigToMDBCINode']), 'expectation'=>0},
    {'shell_command'=>test_command('mariadb', '10.0', ENV['pathToConfigToMDBCIFolder']), 'expectation'=>0},
    {'shell_command'=>test_command('mariadb', '10.0', ENV['pathToConfigToVBOXNode']), 'expectation'=>0},
    {'shell_command'=>test_command('mariadb', '10.0', ENV['pathToConfigToVBOXFolder']), 'expectation'=>0},
    {'shell_command'=>test_command('mariadb', nil, ENV['pathToConfigToVBOXNode']), 'expectation'=>1},
    {'shell_command'=>test_command(nil, '10.0', ENV['pathToConfigToVBOXNode']), 'expectation'=>1},
    {'shell_command'=>test_command('mariadb', '10.0', ENV['pathToConfigToMDBCIBadNode']), 'expectation'=>1},
    {'shell_command'=>test_command('mariadb', '10.0', 'TEST_MACHINE'), 'expectation'=>1}
  ])
end

require 'rspec'
require 'spec_helper'

def test_command (product, product_version, config_path)
  product_name_parameter = ''
  product_version_parameter = ''
  product_name_parameter = "--product #{product}" if product != nil
  product_version_parameter = "--product-version #{product_version}" if product_version != nil
  return "./mdbci install_product #{product_name_parameter} #{product_version_parameter} #{config_path}"
end

def pretest_command (product, product_version, config_path)
  product_name_parameter = ''
  product_version_parameter = ''
  product_name_parameter = "--product #{product}" if product != nil
  product_version_parameter = "--product-version #{product_version}" if product_version != nil
  return "./mdbci setup_repo #{product_name_parameter} #{product_version_parameter} #{config_path}"
end

describe 'test_spec' do
  executeShellCommandsAndTestExitCode ([
    {'shell_command'=>pretest_command('mariadb', '10.0', ENV['pathToConfigToMDBCINode']), 'expectation'=>0},
    {'shell_command'=>test_command('mariadb', nil, ENV['pathToConfigToMDBCINode']), 'expectation'=>0},
    {'shell_command'=>pretest_command('mariadb', '10.0', ENV['pathToConfigToMDBCIFolder']), 'expectation'=>0},
    {'shell_command'=>test_command('mariadb', nil, ENV['pathToConfigToMDBCIFolder']), 'expectation'=>0},
    {'shell_command'=>pretest_command('mariadb', '10.0', ENV['pathToConfigToVBOXNode']), 'expectation'=>0},
    {'shell_command'=>test_command('mariadb', nil, ENV['pathToConfigToVBOXNode']), 'expectation'=>0},
    {'shell_command'=>pretest_command('mariadb', '10.0', ENV['pathToConfigToVBOXFolder']), 'expectation'=>0},
    {'shell_command'=>test_command('mariadb', nil, ENV['pathToConfigToVBOXFolder']), 'expectation'=>0},
    {'shell_command'=>test_command('mariadb', nil, ENV['pathToConfigToVBOXNode']), 'expectation'=>1},
    {'shell_command'=>test_command(nil, '10.0', ENV['pathToConfigToVBOXNode']), 'expectation'=>1},
    {'shell_command'=>test_command('mariadb', '10.0', ENV['pathToConfigToMDBCIBadNode']), 'expectation'=>1},
    {'shell_command'=>test_command('mariadb', '10.0', nil), 'expectation'=>1},
    {'shell_command'=>test_command('mariadb', '10.0', 'TEST_MACHINE'), 'expectation'=>1}
  ])
end

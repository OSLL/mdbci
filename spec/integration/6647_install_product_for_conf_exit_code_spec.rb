require 'rspec'
require_relative '../spec_helper'

CONF_DOCKER = ENV['mdbci_param_conf_docker']
CONF_PPC = ENV['mdbci_param_conf_docker']

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
  execute_shell_commands_and_test_exit_code ([
    {shell_command: pretest_command('mariadb', '10.0', "#{CONF_DOCKER}"), exit_code: 0},
    {shell_command: test_command('mariadb', nil, "#{CONF_DOCKER}"), exit_code: 0},
    {shell_command: pretest_command('mariadb', '10.0', "#{CONF_PPC}"), exit_code: 0},
    {shell_command: test_command('mariadb', nil, "#{CONF_PPC}"), exit_code: 0}
  ])
end

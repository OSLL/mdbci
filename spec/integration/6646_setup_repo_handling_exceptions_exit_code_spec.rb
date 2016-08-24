require 'rspec'
require_relative '../spec_helper'

CONF_DOCKER = ENV['mdbci_param_conf_docker']
CONF_PPC = ENV['mdbci_param_conf_docker']

ORIGIN_SNAP_NAME = 'origin_snap'

def test_command (product, product_version, config_path)
  product_name_parameter = ''
  product_version_parameter = ''
  product_name_parameter = "--product #{product}" if product != nil
  product_version_parameter = "--product-version #{product_version}" if product_version != nil
  return "./mdbci setup_repo #{product_name_parameter} #{product_version_parameter} #{config_path}"
end

describe nil do
  executeShellCommandsAndTestExitCode ([
      {'shell_command' => test_command('mariadb', nil, "#{ENV['mdbci_param_conf_docker']}/node1"), 'expectation' => 1},
      {'shell_command' => test_command(nil, '10.0', ENV['mdbci_param_conf_docker']), 'expectation' => 1},
      {'shell_command' => test_command('mariadb', '10.0', nil), 'expectation' => 1},
      {'shell_command' => test_command('mariadb', '10.0', 'TEST_MACHINE'), 'expectation' => 1}
  ])
end
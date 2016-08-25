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
      {'shell_command' => test_command('mariadb', '10.0', "#{CONF_PPC}/node1"), 'expectation' => 0},
      {'shell_command' => test_command('mariadb', '10.0', "#{CONF_DOCKER}/node1"), 'expectation' => 0}
  ])
end
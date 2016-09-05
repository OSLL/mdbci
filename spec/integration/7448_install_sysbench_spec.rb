require 'rspec'
require_relative '../spec_helper'
require_relative '../../core/helper'

CONF_LIBVIRT = ENV['mdbci_param_conf_libvirt']
NODE_APT = 'node1'
NODE_YUM = 'node2'
#NODE_ZYPPER = 'node3'

NETWORK_CONFIG_POSTFIX = 'network_config'

PRIVATE_IP = 'private_ip'
KEYFILE = 'keyfile'
WHOAMI = 'whoami'

def get_node_data(config_name, node)
  network_config = "#{config_name}_#{NETWORK_CONFIG_POSTFIX}"
  unless File.exist? network_config
    execute_bash("./mdbci show network_config #{config_name}")
  end
  configs = File.read(network_config).split("\n")
  puts configs
  data = Hash.new
  data[PRIVATE_IP] = configs.select { |c| c =~ (/^#{node}_#{PRIVATE_IP}=(.*)/) }
  data[KEYFILE] = configs.select { |c| c =~ (/^#{node}_#{KEYFILE}=(.*)/) }
  data[WHOAMI] = configs.select { |c| c =~ (/^#{node}_#{WHOAMI}=(.*)/) }
  puts data
  data.each { |key, value| data[key] = value.first.split('=')[1]}
  return data
end


APT_DATA = get_node_data(CONF_LIBVIRT, NODE_APT)
YUM_DATA = get_node_data(CONF_LIBVIRT, NODE_YUM)
#ZYPPER_DATA = get_node_data(CONF_LIBVIRT, NODE_YUM)


describe nil do

  before :all do
    execute_bash("./mdbci setup_repo --product mariadb --product-version 10.0 #{CONF_LIBVIRT}/#{NODE_APT}")
    execute_bash("./mdbci install_product --product mariadb #{CONF_LIBVIRT}/#{NODE_APT}")
    execute_bash("./mdbci setup_repo --product mariadb --product-version 10.0 #{CONF_LIBVIRT}/#{NODE_YUM}")
    execute_bash("./mdbci install_product --product mariadb #{CONF_LIBVIRT}/#{NODE_YUM}")
    #execute_bash("./mdbci setup_repo --product mariadb --product-version 10.0 #{CONF_LIBVIRT}/#{NODE_ZYPPER}")
    #execute_bash("./mdbci install_product --product mariadb #{CONF_LIBVIRT}/#{NODE_ZYPPER}")
  end

  it 'installation sysbench with apt' do
    expect(lambda{execute_bash("./scripts/install_sysbench.sh #{APT_DATA[WHOAMI]} #{APT_DATA[PRIVATE_IP]} #{APT_DATA[KEYFILE]}")}).not_to raise_error
  end

  it 'installation sysbench with yum' do
    expect(lambda{execute_bash("./scripts/install_sysbench.sh #{YUM_DATA[WHOAMI]} #{YUM_DATA[PRIVATE_IP]} #{YUM_DATA[KEYFILE]}")}).not_to raise_error
  end

  it 'checking installation sysbench with apt' do
    expect(lambda{execute_bash("./mdbci ssh --command 'which sysbench' #{CONF_LIBVIRT}/#{NODE_APT} --silent")}).not_to raise_error
  end

  it 'checking installation sysbench with yum' do
    expect(lambda{execute_bash("./mdbci ssh --command 'which sysbench' #{CONF_LIBVIRT}/#{NODE_YUM} --silent")}).not_to raise_error
  end

=begin
  it 'checking installation sysbench with zypper' do
    expect(lambda{execute_bash("./mdbci ssh --command 'which sysbench' #{CONF_LIBVIRT}/#{NODE_ZYPPER} --silent")}).not_to raise_error
  end

  it 'installation sysbench with zypper' do
    expect(lambda{execute_bash("./scripts/install_sysbench.sh #{YUM_DATA[WHOAMI]} #{YUM_DATA[PRIVATE_IP]} #{YUM_DATA[KEYFILE]}")}).not_to raise_error
  end
=end

end

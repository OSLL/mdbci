require 'spec_helper'

describe 'mysql_client_test::default on debian-7.0' do
  cached(:debian_70_client_55) do
    ChefSpec::SoloRunner.new(
      platform: 'debian',
      version: '7.0',
      step_into: 'mysql_client'
    ) do |node|
      node.set['mysql']['version'] = '5.5'
    end.converge('mysql_client_test::default')
  end

  # Resource in mysql_client_test::default
  context 'compiling the test recipe' do
    it 'creates mysql_client[default]' do
      expect(debian_70_client_55).to create_mysql_client('default')
    end
  end

  # mysql_service resource internal implementation
  context 'stepping into mysql_client[default] resource' do
    it 'installs package[default :create mysql-client]' do
      expect(debian_70_client_55).to install_package('default :create mysql-client')
        .with(package_name: 'mysql-client')
    end

    it 'installs package[default :create libmysqlclient-dev]' do
      expect(debian_70_client_55).to install_package('default :create libmysqlclient-dev')
        .with(package_name: 'libmysqlclient-dev')
    end
  end
end

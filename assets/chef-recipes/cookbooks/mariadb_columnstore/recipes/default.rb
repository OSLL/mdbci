#
# Cookbook:: mariadb_columnstore
# Recipe:: install
#

include_recipe 'mariadb_columnstore::configure_repository'

package 'Install server' do
  package_name 'mariadb-columnstore-server'
end

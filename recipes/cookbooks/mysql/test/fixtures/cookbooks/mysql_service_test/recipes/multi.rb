# comments!

group 'alice' do
  action :create
end

user 'alice' do
  gid 'alice'
  home '/'
  action :create
end

group 'bob' do
  action :create
end

user 'bob' do
  gid 'bob'
  home '/'
  action :create
end

mysql_service 'default' do
  action :delete
end

# hard code values where we can
mysql_service 'instance-1' do
  version node['mysql']['version']
  bind_address '0.0.0.0'
  port '3307'
  data_dir '/data/instance-1'
  run_user 'alice'
  run_group 'alice'
  action [:create, :start]
end

# pass everything from node attributes
mysql_service 'instance-2' do
  version node['mysql']['version']
  bind_address '0.0.0.0'
  port node['mysql']['port']
  data_dir node['mysql']['data_dir']
  run_user node['mysql']['run_user']
  run_group node['mysql']['run_group']
  initial_root_password node['mysql']['initial_root_password']
  action [:create, :start]
end

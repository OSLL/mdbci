node.set_unless['maria']['instance'] = 'default'

mysql_service node['maria']['instance'] do
  if (defined?(node['maria']['initial_root_password']))
    initial_root_password node['maria']['initial_root_password']
  end
  if (defined?(node['maria']['bind_address']))
    bind_address node['maria']['bind_address']
  end
  if (defined?(node['maria']['port']))
    port node['maria']['port']
  end
  if (defined?(node['maria']['socket']))
    socket node['maria']['socket']
  end
  if (defined?(node['maria']['data_dir']))
    data_dir node['maria']['data_dir']
  end
  action [:create, :start]
end

execute 'Register the system' do
  command 'subscription-manager register '\
          "--username #{node['subscription-manager']['username']} "\
          "--password #{node['subscription-manager']['password']}"
end

execute 'Attach a subscription from a specific pool' do
  command "subscription-manager attach --pool=#{node['subscription-manager']['pool_id']}"
end

execute 'Enable available repositories' do
  command 'subscription-manager repos --enable=*'
end

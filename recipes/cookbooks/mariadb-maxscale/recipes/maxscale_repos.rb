
#
# MariaDB Maxscale repos
#
case node[:platform_family]
  #
  when "debian", "ubuntu"
  # maxscale attributes
  system 'echo Maxscale version: ' + node['maxscale']['version']
  system 'echo Maxscale repo: ' + node['maxscale']['repo']
  system 'echo Maxscale repo key: ' + node['maxscale']['repo_key']
  # Add repo key
  execute "Key add" do
    command "apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 70E4618A8167EE24"
  end
  release_name = '$(lsb_release -cs)'
  system 'echo Platform: $release_name'
  execute "Repository add" do
    command 'echo "deb [arch=amd64] ' + node['maxscale']['repo'] + '/' + node[:platform] + ' ' + release_name + ' main" > /etc/apt/sources.list.d/maxscale.list'
  end
  execute "update" do
    command "apt-get update"
  end
  when "rhel", "fedora", "centos"
  # Add the repo
  template "/etc/yum.repos.d/maxscale.repo" do
    source "maxscale.rhel.erb"
    action :create
  end
  when "suse"
  # Add the repo
  template "/etc/zypp/repos.d/maxscale.repo" do
    source "maxscale.suse.erb"
    action :create
  end
end

include_recipe 'packages::configure_apt'

#
# install default packages
#
[ "net-tools", "psmisc" ].each do |pkg|
  package pkg do
    retries 2
    retry_delay 10
  end
end
#
# Maxscale package attributes
#
system 'echo Maxscale version: ' + node['maxscale']['version']
system 'echo Maxscale repo: ' + node['maxscale']['repo']
system 'echo Maxscale repo key: ' + node['maxscale']['repo_key']
#
# MariaDB Maxscale repos
#
case node[:platform_family]
  #
  when "debian", "ubuntu"

    # Add repo key
    execute "Key add" do
      command "apt-key adv --recv-keys --keyserver keyserver.ubuntu.com " + node['maxscale']['repo_key']
    end

    addrepocmd = 'echo "deb '+ node['maxscale']['repo'] +' " >/etc/apt/sources.list.d/maxscale.list'
    execute "Repository add" do
      command addrepocmd
    end

    execute "update" do
      command "apt-get update"
    end

  when "rhel", "fedora", "centos"

    # Add the repo
    template "/etc/yum.repos.d/maxscale.repo" do
      source "mdbci.maxscale.rhel.erb"
      action :create
    end

  when "suse", "opensuse", "sles"

    # Add the repo
    template "/etc/zypp/repos.d/maxscale.repo" do
      source "mdbci.maxscale.suse.erb"
      action :create
    end

    execute "Refreshing repositories (to avoid password issue)" do
      command "zypper ref"
    end

    execute "Removing maxscale repo (it will be recreated right after removing)" do
      command "rm /etc/zypp/repos.d/maxscale.repo"
    end

    template "/etc/zypp/repos.d/maxscale.repo" do
      source "mdbci.maxscale.suse.erb"
      action :create
    end

end

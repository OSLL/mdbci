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

    # Split MaxScale repository information into parts
    repository = node['maxscale']['repo'].split(/\s+/)
    apt_repository 'maxscale' do
      key node['maxscale']['repo_key']
      uri repository[0]
      components repository.slice(1, repository.size)
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

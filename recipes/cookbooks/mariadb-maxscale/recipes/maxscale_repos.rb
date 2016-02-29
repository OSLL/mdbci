
#
# Chef up log file
#
file "/home/vagrant/"+node['maxscale']['node_name']+"_chef_up.log" do
  owner 'vagrant'
  group 'vagrant'
  mode '0664'
  action :create
end
#
# Install dependencies
#
# install default packages
[ "net-tools", "psmisc" ].each do |pkg|
  package pkg do
    action :install
    not_if do
      case node[:platform_family]
        when "debian", "ubuntu"
          puts "net-tools: DEBIAN OS"
        when "rhel", "fedora", "centos"
          status = system("yum whatprovides ifconfig")
          raise "#{pkg} package or some product repo exception: not found" if status == false
      end
    end
  end
end
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
    command "apt-key adv --recv-keys --keyserver keyserver.ubuntu.com " + node['maxscale']['repo_key']
  end
  #release_name = '$(lsb_release -cs)'
  #system 'echo Platform: $release_name'

  repo = node['maxscale']['repo']
  addrepocmd = 'echo "deb '+ repo +' " >/etc/apt/sources.list.d/maxscale.list'

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

  # Update maxscale repo
  execute "update" do
    command "yum update maxscale"
    not_if do
      status = system("rpm -qa | grep 'maxscale'")
      if status == false
        # move to separate file logger.rb or use chef_handler cookbook
        chef_log = File.open("/home/vagrant/"+node['maxscale']['node_name']+"_chef_up.log", "w")
        unless chef_log.nil?
          chef_log.puts node['maxscale']['node_name']+":maxscale package not found:exit code:"+(status == true ? "1" : "0")
        end
        chef_log.close
        #raise "mariadb-maxscale package not found! Please check product repo!"
      end
    end
  end


  when "suse", "opensuse", "sles"

    # Add the repo
  template "/etc/zypp/repos.d/maxscale.repo" do
    source "mdbci.maxscale.suse.erb"
    action :create
  end
end

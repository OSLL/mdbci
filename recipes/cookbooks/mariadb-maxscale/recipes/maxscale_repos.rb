
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
[ "net-tools", "psmisc" ].each do |pkg|
  package pkg do
    action :install
    not_if do
      case node[:platform_family]
        when "debian", "ubuntu"
          status = system("dpkg -s net-tools")
          raise "#{pkg} package or some product repo not found" if status == false
        when "rhel", "fedora", "centos"
          status = system("rpm -qa | grep 'net-tools'")
          raise "#{pkg} package or some product repo not found" if status == false
        when "opensuse", "sles", "suse"
          status = system("rpm -qa | grep 'net-tools'")
          raise "#{pkg} package or some product repo not found" if status == false
      end
    end
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

    # Update maxscale repo
    execute "update maxscale package" do
      command "apt-get update maxscale"
      not_if do
        status = system("apt-cache search maxscale | grep 'maxscale'")
        if status == false
          # move to separate file logger.rb or use chef_handler cookbook
          chef_log = File.open("/home/vagrant/"+node['maxscale']['node_name']+"_chef_up.log", "w")
          unless chef_log.nil?
            chef_log.puts node['maxscale']['node_name']+":apt:maxscale package not found:exit code:"+(status == true ? "0" : "1")
          end
          chef_log.close
        end
      end
    end

  when "rhel", "fedora", "centos"

    # Add the repo
    template "/etc/yum.repos.d/maxscale.repo" do
      source "mdbci.maxscale.rhel.erb"
      action :create
    end

    # Update maxscale repo
    execute "update maxscale package" do
      command "yum update maxscale"
      not_if do
        status = system("rpm -qa | grep 'maxscale'")
        if status == false
          # move to separate file logger.rb or use chef_handler cookbook
          chef_log = File.open("/home/vagrant/"+node['maxscale']['node_name']+"_chef_up.log", "w")
          unless chef_log.nil?
            chef_log.puts node['maxscale']['node_name']+":rpm:maxscale package not found:exit code:"+(status == true ? "0" : "1")
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

    # Update maxscale repo
    execute "update maxscale package" do
      command "zypper update maxscale"
      not_if do
        status = system("zypper -is | grep 'maxscale'")
        if status == false
          # move to separate file logger.rb or use chef_handler cookbook
          chef_log = File.open("/home/vagrant/"+node['maxscale']['node_name']+"_chef_up.log", "w")
          unless chef_log.nil?
            chef_log.puts node['maxscale']['node_name']+":zypper:maxscale package not found:exit code:"+(status == true ? "0" : "1")
          end
          chef_log.close
        end
      end
    end

end

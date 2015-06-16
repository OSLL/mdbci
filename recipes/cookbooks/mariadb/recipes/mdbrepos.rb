#
node.set_unless['mariadb']['source'] = "enterprise"
#
if node['mariadb']['source'] == "enterprise"
  puts 'MariaDB Enterprise'
  include_recipe "mariadb::init_enterprise"
elsif node['mariadb']['source'] == "community"
  puts 'MariaDB Community'
  include_recipe "mariadb::init_community"
  system 'echo repo: ' + node['mariadb']['other_repo']
  system 'echo distr: ' + node['mariadb']['other_distr']
elsif node['mariadb']['source'] == 'oracle'
  puts 'Oracle MySQL:'
  include_recipe "mariadb::init_oracle"
else
  puts 'MariaDB Distribution'
  include_recipe "mariadb::init_distribution"
end
#
case node[:platform_family]
when "debian"
  execute "Key add" do
    command "apt-key adv --recv-keys --keyserver keyserver.ubuntu.com " + node['ubuntu']['key']
  end
  release_name = '$(lsb_release -cs)'
  system 'echo MariaDB version: ' + node['mariadb']['version']
  system 'echo MariaDB repo: ' + node['mariadb']['deb_repo']
  #
  execute "Repository add" do
    command 'echo "deb ' + node['mariadb']['deb_repo'] + node['mariadb']['deb_distr'] + node['mariadb']['version'] + node['mariadb']['deb_family'] + node[:platform] + ' ' + release_name + ' main" > /etc/apt/sources.list.d/mariadb.list'
  end
  execute "update" do
    command "apt-get update"
  end
when "rhel", "fedora", "centos"
  template "/etc/yum.repos.d/mariadb.repo" do
    source "mariadb.rhel.erb"
    action :create
  end
when "suse"
  template "/etc/zypp/repos.d/mariadb.repo" do
    source "mariadb.suse.erb"
    action :create
  end
  release_name = "if cat /etc/SuSE-release | grep Enterprise &>/dev/null; then echo sles; else echo opensuse; fi"
  execute "Change suse on sles repository" do
    command "cat /etc/zypp/repos.d/mariadb.repo | sed s/PLATFORM/$(" + release_name + ")/g > /etc/zypp/repos.d/mariadb.repo"
  end
when "windows"
  arch = node[:kernel][:machine] == "x86_64" ? "winx64" : "win32"
  
  md5sums_file = "#{Chef::Config[:file_cache_path]}/md5sums.txt"
  remote_file "#{md5sums_file}" do
    source node['mariadb']['other_repo'] + "/" + node['mariadb']['version'] + "/" + arch + "-packages/md5sums.txt"
  end

  file_name = "mariadb-enterprise-" + node['mariadb']['version'] + "-" + arch + ".msi"

  if File.exists?("#{md5sums_file}")
    f = File.open("#{md5sums_file}")
    f.each {|line|
      match = line.split(" ")
      if match[1].end_with?("msi")
        file_name = match[1]
        break
      end
    }
    f.close
  end

  remote_file "#{Chef::Config[:file_cache_path]}/mariadb.msi" do
    source node['mariadb']['other_repo'] + "/" + node['mariadb']['version'] + "/" + arch + "-packages/" + file_name
  end
end

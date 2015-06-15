require 'yaml'


node.set_unless['maria']['source'] = "enterprise"
if node['maria']['source'] == "enterprise"
  puts 'MariaDB Enterprise'
  include_recipe "mariadb::init_enterprise"
  #if File.exist?("enterprise-repos.yml")
  #  enterprise_repos = YAML.load_file("enterprise-repos.yml")["enterprise"]
  #end
  include_recipe "mariadb::init_enterprise"
elsif node['maria']['source'] == "community"
  puts 'MariaDB Community'
  #if File.exist?("community-repos.yml")
  #  community_repos = YAML.load_file("community-repos.yml")["community"]
  #end
  include_recipe "mariadb::init_community"
  system 'echo repo: ' + node['maria']['other_repo']
  system 'echo distr: ' + node['maria']['other_distr']
elsif node['maria']['source'] == 'oracle'
  puts 'Oracle MySQL:'
  #if File.exist?("oracle-mysql-repos.yml")
  #  oracle_repos = YAML.load_file("oracle-mysql-repos.yml")["oracle"]
  #end
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
  system 'echo MariaDB version: ' + node['maria']['version']
  system 'echo MariaDB repo: ' + node['maria']['deb_repo']
  #
  execute "Repository add" do
    command 'echo "deb ' + node['maria']['deb_repo'] + node['maria']['deb_distr'] + node['maria']['version'] + node['maria']['deb_family'] + node[:platform] + ' ' + release_name + ' main" > /etc/apt/sources.list.d/mariadb.list'
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
    source node['maria']['other_repo'] + "/" + node['maria']['version'] + "/" + arch + "-packages/md5sums.txt"
  end

  file_name = "mariadb-enterprise-" + node['maria']['version'] + "-" + arch + ".msi"

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
    source node['maria']['other_repo'] + "/" + node['maria']['version'] + "/" + arch + "-packages/" + file_name
  end
end

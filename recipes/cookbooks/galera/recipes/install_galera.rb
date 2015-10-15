require 'shellwords'

include_recipe "galera::galera_repos"

# Turn off SElinux
if node[:platform] == "centos" and node["platform_version"].to_f >= 6.0 
  execute "Turn off SElinux" do
    command "setenforce 0"
  end
  cookbook_file 'selinux.config' do
    path "/etc/selinux/config"
    action :create
  end
end  # Turn off SElinux

# check and install iptables
case node[:platform_family]
  when "debian", "ubuntu"
    execute "Install iptables-persistent" do
      command "DEBIAN_FRONTEND=noninteractive apt-get -y install iptables-persistent"
    end
  when "rhel", "fedora", "centos"
    if node[:platform] == "centos" and node["platform_version"].to_f >= 7.0
      bash 'Install and configure iptables' do
      code <<-EOF
        yum --assumeyes install iptables-services
        systemctl start iptables
        systemctl enable iptables
      EOF
      end
    else
      bash 'Configure iptables' do
      code <<-EOF
        /sbin/service start iptables
        chkconfig iptables on
      EOF
      end
    end
  when "suse"
    execute "Install iptables and SuSEfirewall2" do
      command "zypper install -y iptables"
      command "zypper install -y SuSEfirewall2"
    end
end

# iptables rules
case node[:platform_family]
  when "debian", "ubuntu", "rhel", "fedora", "centos", "suse"

    ports = ["4567", "4568", "4444", "3306", "4006", "4008", "4009", "4442", "6444"]
    ports.each do |port|
      iptables_cmd = "iptables -I INPUT -p tcp -m tcp --dport "+ port +" -j ACCEPT"
      execute "Opening MariaDB ports." do
        command iptables_cmd
      end
    end

    execute "Opening MariaDB ports.." do
      command "iptables -I INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT"
    end
    
    ports.each do |port|
      iptables_cmd = "iptables -I INPUT -p tcp --dport "+ port +" -j ACCEPT -m state --state NEW"
      execute "Opening MariaDB ports..." do
        command iptables_cmd
      end
    end

end # iptables rules

# TODO: check saving iptables rules after reboot
# save iptables rules
case node[:platform_family]
  when "debian", "ubuntu"
    execute "Save MariaDB iptables rules" do
      command "iptables-save > /etc/iptables/rules.v4"
      #command "/usr/sbin/service iptables-persistent save"
    end
  when "rhel", "centos", "fedora"
    execute "Save MariaDB iptables rules" do
      command "/sbin/service iptables save"
    end
    # service iptables restart
  when "suse"
    execute "Save MariaDB iptables rules" do
      command "iptables-save > /etc/sysconfig/iptables"
    end
end # save iptables rules


system 'echo Platform family: '+node[:platform_family]


# Install packages
case node[:platform_family]
  when "suse"
  if node['galera']['version'] == "10.1"
    execute "install" do
      command "zypper -n install MariaDB-server"
    end
  else
    execute "install" do
      command "zypper -n install MariaDB-Galera-server"
    end
  end

  when "rhel", "fedora", "centos"
    system 'echo shell install on: '+node[:platform_family]
    if node['galera']['version'] == "10.1"
      execute "install" do
        command "yum --assumeyes -c /etc/yum.repos.d/galera.repo install MariaDB-server"
      end
    else
      execute "install" do
        command "yum --assumeyes -c /etc/yum.repos.d/galera.repo install MariaDB-Galera-server"
      end
    end
 
  when "debian"
    if node['galera']['version'] == "10.1"
      package 'mariadb-server'
    else
      package 'mariadb-galera-server'
    end
else
  package 'MariaDB-Galera-server'
end

# cnf_template configuration
case node[:platform_family]

  when "debian", "ubuntu"
  
    createcmd = "mkdir /etc/mysql/my.cnf.d"
    execute "Create cnf_template directory" do
      command createcmd
    end

    copycmd = 'cp /home/vagrant/cnf_templates/' + node['galera']['cnf_template'] + ' /etc/mysql/my.cnf.d'
    execute "Copy mdbci_server.cnf to cnf_template directory" do
      command copycmd
    end

    addlinecmd = 'echo "!includedir /etc/mysql/my.cnf.d" >> /etc/mysql/my.cnf'
    execute "Add mdbci_server.cnf to my.cnf includedir parameter" do
      command addlinecmd
    end

  when "rhel", "fedora", "centos", "suse"

    copycmd = 'cp /home/vagrant/cnf_templates/' + node['galera']['cnf_template'] + ' /etc/my.cnf.d'
    execute "Copy mdbci_server.cnf to cnf_template directory" do
      command copycmd
    end

    # TODO: check if line already exist !!!
    #addlinecmd = "replace '!includedir /etc/my.cnf.d' '!includedir " + node['mariadb']['cnf_template'] + "' -- /etc/my.cnf"
    #execute "Add mdbci_server.cnf to my.cnf includedir parameter" do
    #  command addlinecmd
    #end
end

# configure galera server.cnf file
case node[:platform_family]

  when "debian", "ubuntu"

    libpathcmd = 'sed -i "s|###GALERA-LIB-PATH###|/usr/lib/galera/$(ls /usr/lib/galera | grep so)|g" /etc/mysql/my.cnf.d/#{Shellwords.escape(node["galera"]["cnf_template"])}'
    execute "Configure Galera server.cnf - Get/Set Galera LIB_PATH" do
      command libpathcmd
    end

    provider = IO.read("vagrant/#{Shellwords.escape(node['galera']['node_name'])}_provider")
    if provider == "aws"
      bash 'Configure Galera server.cnf - Get AWS node IP address' do
        code <<-EOF
        node_address=$(curl http://169.254.169.254/latest/meta-data/public-ipv4)
        sed -i "s|###NODE-ADDRESS###|$node_address|g" /etc/mysql/my.cnf.d/#{Shellwords.escape(node['galera']['cnf_template'])}
        EOF
      end
    elsif provider == "virtualbox"
      bash 'Configure Galera server.cnf - Get Virtualbox node IP address' do
        code <<-EOF
        node_address=$(/sbin/ifconfig eth1 | grep "inet " | grep -o -P '(?<=addr:).*(?=  Bcast)')
        sed -i "s|###NODE-ADDRESS###|$node_address|g" /etc/mysql/my.cnf.d/#{Shellwords.escape(node['galera']['cnf_template'])}
        EOF
      end
    end

    nodenamecmd = 'sed -i "s|###NODE-NAME###|#{Shellwords.escape(node["galera"]["node_name"])}|g" /etc/mysql/my.cnf.d/#{Shellwords.escape(node["galera"]["cnf_template"])}'
    execute "Configure Galera server.cnf - NODE_NAME" do
      command nodenamecmd
    end

  when "rhel", "fedora", "centos", "suse"

    bash 'Configure Galera server.cnf - Get/Set Galera LIB_PATH' do
      code <<-EOF
      sed -i \"s|###GALERA-LIB-PATH###|$(rpm -ql galera | grep so)|g\" /etc/my.cnf.d/#{Shellwords.escape(node['galera']['cnf_template'])}
      EOF
    end

    provider = IO.read("/vagrant/#{Shellwords.escape(node['galera']['node_name'])}_provider")
    if provider == "aws"
      bash 'Configure Galera server.cnf - Get AWS node IP address' do
        code <<-EOF
        node_address=$(curl http://169.254.169.254/latest/meta-data/public-ipv4)
        sed -i "s|###NODE-ADDRESS###|$node_address|g" /etc/my.cnf.d/#{Shellwords.escape(node['galera']['cnf_template'])}
        EOF
      end
    elsif provider == "virtualbox"
      bash 'Configure Galera server.cnf - Get Virtualbox node IP address' do
        code <<-EOF
        node_address=$(/sbin/ifconfig eth1 | grep "inet " | grep -o -P '(?<=inet ).*(?=  netmask)')
        sed -i "s|###NODE-ADDRESS###|$node_address|g" /etc/my.cnf.d/#{Shellwords.escape(node['galera']['cnf_template'])}
        EOF
      end
    end

    bash 'Configure Galera server.cnf - Get/Set Galera NODE_NAME' do
      code <<-EOF
      sed -i \"s|###NODE-NAME###|#{Shellwords.escape(node['galera']['node_name'])}|g\" /etc/my.cnf.d/#{Shellwords.escape(node['galera']['cnf_template'])}
      EOF
    end

end

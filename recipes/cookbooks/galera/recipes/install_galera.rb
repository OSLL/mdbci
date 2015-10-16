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

# Install default packages
case node[:platform_family]
  when "suse"
    execute "install" do
      command "zypper install netcat-openbsd rsync sudo"\
        "sed coreutils util-linux curl grep findutils gawk socat iproute"
    end
  when "rhel", "fedora", "centos"
    execute "install" do
      command "yum install netcat-openbsd rsync sudo"\
        "sed coreutils util-linux curl grep findutils gawk socat iproute"
    end
  else # debian
    [
      "netcat-openbsd", "rsync", "sudo", "sed", 
      "coreutils", "util-linux", "curl", "grep", 
      "findutils", "gawk", "socat", "iproute"
    ].each do |pkg|
        package pkg
    end
  else
    package 'MariaDB-Galera-server'
end


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

    # 1. find ###GALERA-LIB-PATH### and replace with proper path to libgalera_smm.so. use dpkg or yum for list package so libs
    #galera_lib_path=$()
    #sed -i "s/###GALERA-LIB-PATH###/$galera_lib_path/g" /etc/mysql/my.cnf.d/mdbci_server.cnf

    # 2. find ###NODE-ADDRESS### and replace with private IP address
    # (IP address of node for VBox/Qemu and output of curl http://169.254.169.254/latest/meta-data/local-ipv4 for AWS
    #node_address=$()
    #sed -i "s/###NODE-ADDRESS###/$node_address/g" /etc/mysql/my.cnf.d/mdbci_server.cnf

    # 3. ###NODE-NAME### string have to be replaced with node name from node definition
    #node_name=$()
    #sed -i "s/###NODE-NAME###/$node_name/g" /etc/mysql/my.cnf.d/mdbci_server.cnf

  when "rhel", "fedora", "centos", "suse"

    # same as
   
end

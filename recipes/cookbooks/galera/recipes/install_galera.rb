require 'shellwords'

include_recipe "galera::galera_repos"
include_recipe "ntp::default"

# Install default packages
[
  "rsync", "sudo", "sed", 
  "coreutils", "util-linux", "curl", "grep", 
  "findutils", "gawk", "iproute"
].each do |pkg|
  package pkg
end
case node[:platform_family]
  when "rhel", "fedora", "centos"
    package "wget"
    if node[:platform] == "centos"
      if node["platform_version"].to_f >= 6.0 
        execute "add_socat_repo_centos_ge6" do
          command "wget -P /etc/yum.repos.d http://www.convirture.com/repos/definitions/rhel/6.x/convirt.repo"
        end
      else
        execute "add_socat_repo_centos_le5" do
          command "wget -P /etc/yum.repos.d http://www.convirture.com/repos/definitions/rhel/5.x/convirt.repo"
        end
      end
    end
    package "nc"
  else # debian, suse
    package "netcat"
end
package "socat"


# Turn off SElinux
if node[:platform] == "centos" and node["platform_version"].to_f >= 6.0
  # TODO: centos7 don't have selinux
  bash 'Turn off SElinux on CentOS >= 6.0' do
  code <<-EOF
    selinuxenabled && flag=enabled || flag=disabled
    if [[ $flag == 'enabled' ]];
    then
      /usr/sbin/setenforce 0
    else
      echo "SElinux already disabled!"
    fi
  EOF
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

# iptables ports
case node[:platform_family]
  when "debian", "ubuntu", "rhel", "fedora", "centos", "suse"
    ["4567", "4568", "4444", "3306", "4006", "4008", "4009", "4442", "6444"].each do |port|
      execute "Open port #{port}" do
        command "iptables -I INPUT -p tcp -m tcp --dport "+port+" -j ACCEPT"
        command "iptables -I INPUT -p tcp --dport "+ port +" -j ACCEPT -m state --state NEW"
      end
    end
end # iptables ports

# TODO: check saving iptables rules after reboot
# save iptables rules
case node[:platform_family]
  when "debian", "ubuntu"
    execute "Save iptables rules" do
      command "iptables-save > /etc/iptables/rules.v4"
      #command "/usr/sbin/service iptables-persistent save"
    end
  when "rhel", "centos", "fedora"
    if node[:platform] == "centos" and node["platform_version"].to_f >= 7.0
      bash 'Save iptables rules on CentOS 7' do
      code <<-EOF
        # TODO: use firewalld
        iptables-save > /etc/sysconfig/iptables
      EOF
      end
    else
      bash 'Save iptables rules on CentOS >= 6.0' do
      code <<-EOF
        /sbin/service iptables save
      EOF
      end
    end
    # service iptables restart
  when "suse"
    execute "Save iptables rules" do
      command "iptables-save > /etc/sysconfig/iptables"
    end
end # save iptables rules


system 'echo Platform family: '+node[:platform_family]


# Install packages
case node[:platform_family]
  when "suse"
  if node['galera']['version'] == "10.1" || node['galera']['version'] == "10.2" || node['galera']['version'] == "10.3"
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
    if node['galera']['version'] == "10.1" || node['galera']['version'] == "10.2" || node['galera']['version'] == "10.3"
      execute "install galera 10.1" do
        command "yum --assumeyes -c /etc/yum.repos.d/galera.repo install MariaDB-server"
      end
    elsif node['galera']['version'] == "10.0"
      execute "install galera 10.0" do
        command "yum --assumeyes -c /etc/yum.repos.d/galera.repo install MariaDB-Galera-server && yum --assumeyes install galera"
      end
    else
      execute "install galera" do
        command "yum --assumeyes -c /etc/yum.repos.d/galera.repo install MariaDB-Galera-server"
      end
    end
 
  when "debian"
    if node['galera']['version'] == "10.1" || node['galera']['version'] == "10.2" || node['galera']['version'] == "10.3"
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

    bash 'Configure Galera server.cnf - Get/Set Galera LIB_PATH' do
      code <<-EOF
      sed -i "s|###GALERA-LIB-PATH###|/usr/lib/galera/$(ls /usr/lib/galera | grep so)|g\" /etc/mysql/my.cnf.d/#{Shellwords.escape(node['galera']['cnf_template'])}
      EOF
    end

    provider = IO.read("vagrant/provider")
    if provider == "aws"
      bash 'Configure Galera server.cnf - Get AWS node IP address' do
        code <<-EOF
        node_address=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)
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
    elsif provider == "libvirt"
      bash 'Configure Galera server.cnf - Get Libvirt node IP address' do
        code <<-EOF
        node_address=$(/sbin/ifconfig eth0 | grep -o -P '(?<=inet ).*(?=  netmask)')
        sed -i "s|###NODE-ADDRESS###|$node_address|g" /etc/mysql/my.cnf.d/#{Shellwords.escape(node['galera']['cnf_template'])}
        EOF
      end
    elsif provider == "docker"
      bash 'Configure Galera server.cnf - Get Docker node IP address' do
        code <<-EOF
        node_address=$(/sbin/ifconfig eth0 | grep "inet " | grep -o -P '(?<=addr:).*(?=  Bcast)')
        sed -i "s|###NODE-ADDRESS###|$node_address|g" /etc/mysql/my.cnf.d/#{Shellwords.escape(node['galera']['cnf_template'])}
        EOF
      end
    end

    bash 'Configure Galera server.cnf - Get/Set Galera NODE_NAME' do
      code <<-EOF
      sed -i "s|###NODE-NAME###|#{Shellwords.escape(node['galera']['node_name'])}|g\" /etc/mysql/my.cnf.d/#{Shellwords.escape(node['galera']['cnf_template'])}
      EOF
    end

  when "rhel", "fedora", "centos", "suse"

    bash 'Configure Galera server.cnf - Get/Set Galera LIB_PATH' do
      code <<-EOF
      sed -i "s|###GALERA-LIB-PATH###|$(rpm -ql galera | grep so)|g\" /etc/my.cnf.d/#{Shellwords.escape(node['galera']['cnf_template'])}
      EOF
    end

    provider = IO.read("/vagrant/provider")
    if provider == "aws"
      bash 'Configure Galera server.cnf - Get AWS node IP address' do
        code <<-EOF
        node_address=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)
        sed -i "s|###NODE-ADDRESS###|$node_address|g" /etc/my.cnf.d/#{Shellwords.escape(node['galera']['cnf_template'])}
        EOF
      end
    elsif provider == "virtualbox"
      bash 'Configure Galera server.cnf - Get Virtualbox node IP address' do
        code <<-EOF
        node_address=$(/sbin/ifconfig eth1 | grep "inet " | grep -o -P '(?<=addr:).*(?=  Bcast)')
        sed -i "s|###NODE-ADDRESS###|$node_address|g" /etc/my.cnf.d/#{Shellwords.escape(node['galera']['cnf_template'])}
        EOF
      end
    elsif provider == "libvirt"
      bash 'Configure Galera server.cnf - Get Libvirt node IP address' do
        code <<-EOF
        node_address=$(/sbin/ifconfig eth0 | grep -o -P '(?<=inet ).*(?=  netmask)')
        sed -i "s|###NODE-ADDRESS###|$node_address|g" /etc/my.cnf.d/#{Shellwords.escape(node['galera']['cnf_template'])}
        EOF
      end
    elsif provider == "docker"
      bash 'Configure Galera server.cnf - Get Docker node IP address' do
        code <<-EOF
        node_address=$(/sbin/ifconfig eth0 | grep -o -P '(?<=inet ).*(?=  netmask)')
        sed -i "s|###NODE-ADDRESS###|$node_address|g" /etc/my.cnf.d/#{Shellwords.escape(node['galera']['cnf_template'])}
        EOF
      end
    end

    bash 'Configure Galera server.cnf - Get/Set Galera NODE_NAME' do
      code <<-EOF
      sed -i "s|###NODE-NAME###|#{Shellwords.escape(node['galera']['node_name'])}|g\" /etc/my.cnf.d/#{Shellwords.escape(node['galera']['cnf_template'])}
      EOF
    end

end

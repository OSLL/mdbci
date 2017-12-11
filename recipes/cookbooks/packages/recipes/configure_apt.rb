#
# Enshure that https transport is installed on debian
#
if node[:platform_family] == 'debian' || node[:platform_family] == 'ubuntu'
  # Ensure that the machine is syncrhonized with the server
  apt_update 'update'

  # Install required packages
  package 'apt-transport-https'
end

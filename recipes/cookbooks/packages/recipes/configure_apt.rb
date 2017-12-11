#
# Enshure that https transport is installed on debian
#
if node[:platform_family] == 'debian' || node[:platform_family] == 'ubuntu'
  package 'apt-transport-https'
end

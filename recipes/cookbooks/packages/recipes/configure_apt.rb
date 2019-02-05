#
# Enshure that https transport is installed on debian
#
if node[:platform_family] == 'debian' || node[:platform_family] == 'ubuntu'
  # Ensure that the machine is syncrhonized with the server
  apt_update 'update'

  # Install required packages
  %w(apt-transport-https dirmngr ntpdate).each do |package_name|
    package package_name do
      retries 2
      retry_delay 10
    end
  end
end

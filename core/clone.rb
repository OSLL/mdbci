require_relative 'out'
require_relative 'helper'

UUID_FOR_DOMAIN_NOT_FOUND_ERROR = 'uuid for domain is not found'

def get_libvirt_uuid_by_domain_name(domain_name)
  list_output = execute_bash('virsh -q list --all | awk \'{print $2}\'', true).to_s.split "\n"
  list_uuid_output = execute_bash('virsh -q list --uuid --all', true).to_s.split "\n"
  list_output.zip(list_uuid_output).each do |domain, uuid|
    return uuid if domain == domain_name
  end
  raise "#{domain_name}: #{UUID_FOR_DOMAIN_NOT_FOUND_ERROR}"
end



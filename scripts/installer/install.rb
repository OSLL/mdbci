#!/usr/bin/env ruby

KNOWN_PLATFORMS = %w[ubuntu debian rhel]

def run_and_log
end

# Method tries to detect the system we are currently running.
# @returns [String] code name for the system we are running
def detect_platform
  os_version = File.readlines('/etc/os-release').map do |line|
    line.strip.split('=')
  end.reduce({}) do |hash, (key, value)|
    hash[key] = value
    hash
  end
  id = os_version['ID']
  return id if KNOWN_PLATFORMS.include?(id)
  os_version['ID_LIKE'].gsub(/"/, '').split.find do |platform|
    KNOWN_PLATFORMS.include?(platform)
  end
end

# Update the
def update_system(platform)
  case platform
  when 'ubuntu', 'debian'
  end
end

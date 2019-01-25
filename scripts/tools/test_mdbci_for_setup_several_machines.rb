#!/usr/bin/env ruby

# Script setups several configurations and initiate them
# at the same time. The script checks the ability and
# correctness of work mdbci and the vagrant when configuring
# multiple machines simultaneously.
#
# The user can use the script options to set the number of configurations
# for each provider, the number of machines in the configuration,
# the box used for each provider.
#
# As a result, the script will output the results of the configuration
# of each configuration to the terminal, and also create logs of the execution
# of each configuration in the directory ./test_dirs.

require 'fileutils'
require 'json'
require 'open3'
require 'optparse'
require 'workers'

platforms = {
    libvirt: %w[centos_7_libvirt ubuntu_xenial_libvirt debian_stretch_libvirt suse_15_libvirt],
    aws: %w[centos_7_aws ubuntu_xenial_aws debian_stretch_aws suse_13_aws]
}
configs_count = { libvirt: 0, aws: 0 }
vms_dir = File.expand_path('./test_dirs', __dir__)
mdbci = File.expand_path('../../mdbci', __dir__)
nodes_count = 2
selected_platforms = { libvirt: nil, aws: nil }

OptionParser.new do |opts|
  opts.banner = 'Special script to test whether MDBCI can setup several '\
                'vagrant libvirt and vagrant aws driven machines'

  opts.on('-h', '--help', 'Show help and exit') do
    puts "Example of usage:\n./test_mdbci_for_setup_several_machines --libvirt=2"\
         '--aws=1 -n3 --libvirt-box=centos_7_libvirt'
    puts opts
    exit
  end

  opts.on('-nNODES', '--nodes=NODES', 'Number of generated nodes in configs') do |nodes|
    nodes_count = nodes.to_i
  end

  opts.on('--libvirt=CONFIGS_COUNT', 'Number of generated libvirt configs.') do |libvirt_configs_count|
    configs_count[:libvirt] = libvirt_configs_count.to_i
  end

  opts.on('--aws=CONFIGS_COUNT', 'Number of generated AWS configs.') do |aws_configs_count|
    configs_count[:aws] = aws_configs_count.to_i
  end

  opts.on('--libvirt-box=BOX', 'Box for generated templates.') do |box|
    selected_platforms[:libvirt] = box
  end

  opts.on('--aws-box=BOX', 'Box for generated templates.') do |box|
    selected_platforms[:aws] = box
  end

  opts.on('-mMDBCI', '--mdbci=MDBCI', 'Path to MDBCI to use.') do |path|
    mdbci = File.expand_path(path)
  end
end.parse!

FileUtils.rm_rf(vms_dir)
FileUtils.mkdir_p(vms_dir)

def write_configuration(selected_platforms, platforms, template_path, config_id, nodes_count, provider)
  configuration = nodes_count.times.map do |node_num|
    name = "config_#{config_id}_node_#{node_num}"
    [name, { hostname: name.delete('_'), box: selected_platforms[provider] || platforms[provider].sample }]
  end.to_h
  File.write(template_path, JSON.pretty_generate(configuration))
end

puts 'Create JSON-templates'
templates = []
configs_count.each do |provider, count|
  count.times do |index|
    configuration_path = File.expand_path("config_#{provider}_#{index}", vms_dir)
    template_path = "#{configuration_path}.json"
    templates << template_path
    write_configuration(selected_platforms, platforms, template_path, index, nodes_count, provider)
  end
end

puts 'Generate configurations'
configurations = []
templates.each do |template|
  configuration_path = File.join(File.dirname(template), File.basename(template, '.json'))
  generate_result, status = Open3.capture2e("#{mdbci} generate --template #{template} #{configuration_path}")
  unless status.success?
    puts "Error while generating #{template}"
    puts generate_result
    next
  end
  configurations << configuration_path
end

puts 'Up configurations'
Workers.map(configurations) do |configuration|
  result, status = Open3.capture2e("#{mdbci} up #{configuration} --attempts 1")
  File.write("#{configuration}_log_#{status.success? ? 'success' : 'fail'}.txt", result)
  if status.success?
    puts "Success for #{configuration}"
  else
    puts "Error for #{configuration}"
  end
end

puts 'Destroy configurations'
configurations.each do |configuration|
  Open3.capture2e("#{mdbci} destroy #{configuration}")
end

# (0_о) 
require_relative '../models/network_config_file'
require_relative '../services/machine_configurator'
require_relative '../network'
require 'net/ssh'

# rubocop:disable Metrics/MethodLength
class ConfigureNetworkCommand
  def self.publicKeysSsh(args, keyFile, labels, out)
    vm = MachineConfigurator.new(out)
    raise 'Configuration name is required' if args.nil?
  
    args = args.split('/')
       
    unless Dir.exists? args[0]
      raise "Directory with nodes does not exists: #{args[0]}"
    end
    
    configurationDir = Dir.new(args[0])
    network = Network.new
    
    configurationDir.entries.each  do |node|
      next if (node == '.' || node == '..')
      pathNode =  configurationDir.path + '/' + node
      if File.directory? (pathNode)
        network.loadNodes pathNode
      end
    end
  
    if network.nodes.empty?
      raise "No aws, vbox, libvirt, docker nodes found in #{args[0]}"
    end
  
    if args[1].nil? # No node argument, copy keys to all nodes
      if labels.nil?
        network.nodes.each do |node|
          if node.nil?
            raise "No such node with name #{args[1]} in #{args[0]}"
          end
        
          config = NetworkConfigFile.new(configurationDir.path + '/' + node.name + '_network_config')
          machine = {"whoami" => config.configs[node.name]["whoami"], "network" => config.configs[node.name]["network"],
            "keyfile" => config.configs[node.name]["keyfile"] }
          upload_ssh_file(machine, keyFile, vm)
        end
      else
        network.nodes.each do |node|
          if node.nil?
            raise "No such node with name #{args[1]} in #{args[0]}"
          end
          unless node.config.template[node.name]["labels"].nil?
            if node.config.template[node.name]["labels"].include? labels
              config = NetworkConfigFile.new(configurationDir.path + '/' + node.name + '_network_config')
              machine = {"whoami" => config.configs[node.name]["whoami"], "network" => config.configs[node.name]["network"],
                "keyfile" => config.configs[node.name]["keyfile"] }
              upload_ssh_file(machine, keyFile, vm)
            end
          end
        end
      end
    else
      node = network.nodes.find { |elem| elem.name == args[1] }
  
      if node.nil?
        raise "No such node with name #{args[1]} in #{args[0]}"
      end
      config = NetworkConfigFile.new(configurationDir.path + '/' + node.name + '_network_config')
      machine = {"whoami" => config.configs[node.name]["whoami"], "network" => config.configs[node.name]["network"],
        "keyfile" => config.configs[node.name]["keyfile"] }
      upload_ssh_file(machine, keyFile, vm)
    end
    
    exit_code = 0
  end
    
  def self.upload_ssh_file(machine, keyFile, vm)
    options = Net::SSH.configuration_for(machine['network'], true)
    options[:auth_methods] = %w[publickey none]
    options[:verify_host_key] = false
    options[:keys] = [machine['keyfile']]
    Net::SSH.start(machine['network'], machine['whoami'], options) do |ssh|  
      vm.upload_file(ssh, keyFile, ".ssh/authorized_keys", false)
    end 
  end
end
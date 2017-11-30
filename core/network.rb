require 'find'

require_relative 'node'
require_relative 'out'
#require_relative 'session'
require_relative 'helper'

class Network

  attr_accessor :nodes

  def initialize
    @nodes = Array.new
  end

  def getNodeInfo(config, node)
    node = Node.new(config, node)
    @nodes.push(node)
  end

  # TODO BUG 6633
  def loadNodes(config)
    $out.info 'Load configuration nodes from vagrant status ...'

    Dir.chdir config.to_s

    vagrant_out = `vagrant status`
    list = vagrant_out.split("\n")
=begin
  Vagrant prints node info in next format:
  >Current machine states:
  >
  >node0                     running (virtualbox)
  >node1                     running (virtualbox)
  >
  >This environment represents multiple VMs. The VMs are all listed
  >above with their current state. For more information about a specific
  >VM, run `vagrant status NAME`.
  >

  VBOX Node info is located in (2..END-3) lines
  AWS Node info is located in (2..END-4) lines

=end

    count = 0
    provider = ["virtualbox", "aws", "libvirt", "docker"]
    list.each do |line|
      provider.each do |item|
        count += 1 if line.to_s.include?(item)
      end
    end

    # Log offset: 4 - for ONE node, 5 - for multiple nodes
    if count == 1; offset = 4; else offset = 5; end

    (2..list.length-offset).each do |x|
      getNodeInfo(config, list[x])
    end
  end

  def self.getBoxParameters(node_param)
    box = node_param['box'].to_s
    raise "Can not find box parameter for node #{node_name}" if box.empty?
    box_params = $session.boxes.getBox(box)
    raise "Can not find box #{box} node #{node_param} in #{dir}" if box_params.empty?
    return box_params
  end

  def self.getBoxParameterKeyPath(dir,node,pwd)
    result_hash = Hash.new()
    node_name = node[0]
    node_params = node[1]
    box_params = getBoxParameters(node_params)
    key_path = "#{$mdbci_exec_dir}/KEYS/#{box_params['keyfile']}"
    unless File.exist?(key_path)
      raise "Key file #{box_params['keyfile']} is not found for node #{node_name} in #{dir}"
    end
    result_hash["key"] = key_path.to_s
    return result_hash
  end

  def self.showKeyFile(name=nil)
    result_keys = getKeyFile(name)

    result_keys.each do |hash|
      $out.out(hash["key"].to_s)
    end
    return 0
  end

  def self.getKeyFile(name)
    result = Array.new()
    pwd = Dir.pwd
    raise 'Configuration name is required' if name.nil?
    args = name.split('/')
    dir = args[0]
    node_arg = args[1]
    # mdbci ppc64 boxes
    if File.exist?(dir+'/mdbci_template')
      $session.loadMdbciNodes dir
      raise "MDBCI nodes are not found in #{dir}" if $session.mdbciNodes.empty?
      if node_arg.nil?
        $session.mdbciNodes.each do |node|
          key_path = getBoxParameterKeyPath(dir,node,pwd)
          result.push(key_path)
        end
      else
        mdbci_node = $session.mdbciNodes.find { |elem| elem[0].to_s == node_arg }
        raise "MDBCI node is not found in #{dir}" if mdbci_node.nil?
        key_path = getBoxParameterKeyPath(dir,mdbci_node,pwd)
        result.push(key_path)
      end
    else
      configPath = pwd.to_s + '/' + dir
      unless Dir.exists? configPath
        raise 'Configuration with such name does not exists'
      end
      Dir.chdir configPath
      cmd = "vagrant ssh-config #{node_arg} | grep IdentityFile"
      vagrant_out = `#{cmd}`
      raise "Command #{cmd} exit with non-zero exit code: #{$?.exitstatus}" if $?.exitstatus != 0
      tempHash = { 'key' => vagrant_out.split(' ')[1] }
      result.push(tempHash)
      Dir.chdir pwd
    end
    return result
  end

  def self.show(name=nil)
    results = getNetwork(name)
    results.each do |hash|
      $out.out hash["ip"]
    end
    return 0
  end

  def self.getNetwork(name)
    results = Array.new()
    pwd = Dir.pwd

    if name.nil?
      raise 'Configuration name is required'
    end

    args = name.split('/')
    directory = args[0]
    node_arg = args[1]
    # mdbci ppc64 boxes
    if File.exist?(directory+'/mdbci_template')
      $session.loadMdbciNodes directory
      if node_arg.nil?
        if $session.mdbciNodes.empty?
          raise "MDBCI nodes not found in #{directory}"
        end
        $session.mdbciNodes.each do |node|
          results.push(getBoxParameter(node, 'IP'))
        end
      else
        mdbci_node = $session.mdbciNodes.find { |elem| elem[0].to_s == node_arg }
        if mdbci_node.nil?
          raise "mdbci node #{mdbci_node[1].to_s} not found!"
        end
        results.push(getBoxParameter(mdbci_node, 'IP'))
      end
    else # aws, vbox nodes
      unless Dir.exist? directory
        raise "Configuration not found: #{directory}"
      end
      network = Network.new
      network.loadNodes pwd.to_s+'/'+directory # load nodes from dir
      if node_arg.nil? # No node argument, show all config
        network.nodes.each do |node|
          temp_var = getIpWrapper(node,pwd)
          results.push(getIpWrapper(node,pwd))
        end
      else
        node = network.nodes.find { |elem| elem.name == node_arg}
        results.push(getIpWrapper(node,pwd))
      end
    end
    Dir.chdir pwd
    return results
  end

  def self.getIpWrapper(node, pwd)
    attempts = 10
    duration = 5
    while attempts > 0
        begin
           node.getIp(node.provider, false)
           break
        rescue Exception => e
           Dir.chdir pwd
           $out.warning(e.message)
           sleep duration
           attempts = attempts - 1
        end
    end
    if attempts == 0
        Dir.chdir pwd
        raise "Incorrect node"
    end
    hash={ 'ip' => node.ip.to_s }
    return hash
  end

  def self.getBoxParameter(node,param)
    result = Hash.new()
    box = node[1]['box'].to_s
    if box.empty?
      raise "Can not read box parameter of node #{directory}"
    end
    box_params = $session.boxes.getBox(box)
    result["node"] = node[0].to_s
    result[param] = box_params[param].to_s
 ##   $out.info 'Node: ' + node[0].to_s
 ##   $out.out box_params[param].to_s
    return result
  end

  # TODO - move mdbci box definition to new class - MdbciNode < Node
  def self.private_ip(name)
    private_ip = getIP(name)
    private_ip.each do |hash|
      $out.info("Node: "+hash["node"])
      $out.out(hash["ip"])
    end
    return 0
  end

  def self.getIP(args)
    pwd = Dir.pwd
    result_ip = Array.new()
    raise 'Configuration name is required' if args.nil?
    params = args.split('/')
    dir = params[0]
    node_arg = params[1]

    # mdbci box
    if File.exist?(dir+'/mdbci_template')
      $session.loadMdbciNodes dir
      raise "MDBCI nodes are not found in #{dir}" if $session.mdbciNodes.empty?
      if node_arg.nil?     # read ip for all nodes
        $session.mdbciNodes.each do |node|
          box_params = getBoxParameters(node[1])
          result_ip.push({'node' =>node[0], 'ip' =>getNodeParam('IP', node[0], box_params)['IP']})
        end
      else
        mdbci_node = $session.mdbciNodes.find { |elem| elem[0].to_s == node_arg }
        raise "MDBCI node #{node_arg} is not found in #{dir}" if mdbci_node.nil?
        box_params = getBoxParameters(mdbci_node[1])
        result_ip.push({'node' =>mdbci_node[0], 'ip' =>getNodeParam('IP', mdbci_node[0], box_params)['IP']})
      end
    else # aws, vbox nodes
      raise "Can not find directory #{dir}" unless Dir.exists? dir
      network = Network.new
      network.loadNodes pwd.to_s+'/'+dir # load nodes from dir
      raise "Nodes are not found in #{dir}" if network.nodes.empty?
      if node_arg.nil? # No node argument, show all config
        network.nodes.each do |node|
          result_ip.push(getNodeIP(node))
        end
      else
        node = network.nodes.find { |elem| elem.name == node_arg}
        raise "Node #{node_arg} is not found in #{dir}" if node.nil?
        result_ip.push(getNodeIP(node))
      end
    end
    Dir.chdir pwd
    return result_ip
  end

  def self.getNodeIP(node)
    result = Hash.new("")
    exit_code = node.getIp(node.provider, true)
    raise "Can not get IP for #{node.name} in #{dir}" if exit_code != 0
    result["node"] = node.name.to_s
    result["ip"] = node.ip.to_s
    return result
  end

  def self.getNodeParam(param,node_name,box_params)
    result = Hash.new
    result["node"] = node_name.to_s
    result[param.to_s] = box_params[param].to_s
    return result
  end

end

COMMAND_WHOAMI='whoami'
COMMAND_HOSTNAME='hostname'
LIBVITR_IPV6 = "/sbin/ip -6 addr | grep -m1 global | awk -F' ' '{print $2}' | awk -F'/' '{print $1}'"
DOCKER_IPV6 = "/sbin/ip -6 addr | grep -m1 'scope link' | awk -F' ' '{print $2}' | awk -F'/' '{print $1}'"
def printConfigurationNetworkInfoToFile(configuration=nil,node='')

  open("#{configuration}_network_config", 'w') do |f|
    configurationNetworkInfo = collectConfigurationNetworkInfo(configuration,node)
    configurationNetworkInfo.each do |key, value|
      # TODO Add correct array conversion
      f.puts "#{key}=#{value}"
    end
  end
  $out.info "Full path of #{configuration}_network_config: " + File.expand_path("#{configuration}_network_config")
  return 0

end

def collectConfigurationNetworkInfo(configuration,node_one='')

  raise 'configuration name is required' if configuration.nil?
  raise 'configuration does not exist' unless Dir.exist? configuration

  configurationNetworkInfo = Hash.new
  if node_one.empty?
    nodes = get_nodes(configuration)
  else
    nodes = [node_one]
  end
  nodes.each do |node|
    configPath = "#{configuration}/#{node}"
    configurationNetworkInfo["#{node}_network"] = Network.getNetwork(configPath)[0]["ip"].to_s
    configurationNetworkInfo["#{node}_keyfile"] = Network.getKeyFile(configPath)[0]["key"].to_s
    configurationNetworkInfo["#{node}_private_ip"] = Network.getIP(configPath)[0]["ip"].to_s
    configurationNetworkInfo["#{node}_whoami"] = $session.getSSH(configPath, COMMAND_WHOAMI)[0].chomp
    configurationNetworkInfo["#{node}_hostname"] = $session.getSSH(configPath, COMMAND_HOSTNAME)[0].chomp
    if $session.ipv6
      provider = get_provider(configuration)
      if provider == 'libvirt'
        configurationNetworkInfo["#{node}_network6"] = in_dir(configuration){`vagrant ssh #{node} -- #{LIBVITR_IPV6}`.chop}
      elsif provider == 'docker'
        configurationNetworkInfo["#{node}_network6"] = in_dir(configuration){`vagrant ssh #{node} -- #{DOCKER_IPV6}`.chop}
      end
    end
  end
  return configurationNetworkInfo
end

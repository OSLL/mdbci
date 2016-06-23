require 'find'

require_relative 'node'
require_relative 'out'
#require_relative 'session'

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


  def self.showKeyFile(name)
    #TODO refactor with show
    pwd = Dir.pwd
    raise 'Configuration name is required' if name.nil?
    args = name.split('/')
    dir = args[0]
    node_arg = args[1]
    # mdbci ppc64 boxes
    if File.exist?(dir+'/mdbci_template')
      $session.loadMdbciNodes dir
      if node_arg.nil?
        raise "MDBCI nodes are not found in #{dir}" if $session.mdbciNodes.empty?
        $session.mdbciNodes.each do |node|
          key_path = getBoxParams(dir,node,pwd)
          $out.out key_path
        end
      else
        mdbci_node = $session.mdbciNodes.find { |elem| elem[0].to_s == node_arg }
        raise "MDBCI nodes are not found in #{dir}" if $session.mdbciNodes.empty? if mdbci_node.nil?
        key_path = getBoxParams(dir,mdbci_node,pwd)
        $out.out key_path
      end
    else
      unless Dir.exists? pwd.to_s + '/' + dir
        raise 'Configuration with such name does not exists'
      end
      Dir.chdir pwd.to_s + '/' + dir
      cmd = "vagrant ssh-config #{node_arg} | grep IdentityFile"
      vagrant_out = `#{cmd}`
      raise "Command #{cmd} exit with non-zero exit code: #{$?.exitstatus}" if $?.exitstatus != 0
      $out.out vagrant_out.split(' ')[1]
      Dir.chdir pwd
    end
    return 0
  end

  def getBoxParams(dir,node,pwd)
    node_name = node[0]
    node_params = node[1]
    box = node_params['box'].to_s
    raise "Box parameter is not found for node #{node_name} in #{dir}" if box.empty?
    box_params = $session.boxes.getBox(box)
    raise "Box #{box} is not found for node #{node_name} in #{dir}" if box_params.nil?
    $out.info 'Node: ' + node_name.to_s
    key_path = "#{pwd}/KEYS/#{box_params['keyfile']}"
    unless File.exist?(key_path)
      raise "Key file #{box_params['keyfile']} is not found for node #{node_name} in #{dir}"
    end
    return key_path
  end

  def self.show(name)
    exit_code = 1
    pwd = Dir.pwd

    if name.nil?
      raise 'Configuration name is required'
    end

    args = name.split('/')

    # mdbci ppc64 boxes
    if File.exist?(args[0]+'/mdbci_template')
      $session.loadMdbciNodes args[0]
      if args[1].nil?
        if $session.mdbciNodes.empty?
          raise "MDBCI nodes not found in #{args[0]}"
        end
        $session.mdbciNodes.each do |node|
          box = node[1]['box'].to_s
          if !box.empty?
            box_params = $session.boxes.getBox(box)
            $out.info 'Node: ' + node[0].to_s
            $out.out box_params['IP'].to_s
          else
            raise "Can not read box parameter of node #{args[0]}"
          end
        end
      else
        mdbci_node = $session.mdbciNodes.find { |elem| elem[0].to_s == args[1] }
        if mdbci_node.nil?
          raise "mdbci node #{mdbci_node[1].to_s} not found!"
        end
        box = mdbci_node[1]['box'].to_s
        if !box.empty?
          mdbci_params = $session.boxes.getBox(box)
          $out.info 'Node: ' + args[1].to_s
          $out.out mdbci_params['IP'].to_s
        else
          raise "Can not read parameter 'box' of node #{args[1]}"
        end
      end
    else # aws, vbox nodes

      unless Dir.exists? args[0]
        raise "Configuration not found: #{args[0]}"
      end

      network = Network.new
      network.loadNodes pwd.to_s+'/'+args[0] # load nodes from dir

      if args[1].nil? # No node argument, show all config
        network.nodes.each do |node|
          exit_code = node.getIp(node.provider, false)
          $out.out node.ip.to_s
        end
      else
        node = network.nodes.find { |elem| elem.name == args[1]}
        exit_code = node.getIp(node.provider, false)
        $out.out node.ip.to_s
      end
    end
    Dir.chdir pwd

    return exit_code
  end

  # TODO - move mdbci box definition to new class - MdbciNode < Node
  def self.private_ip(name)
    pwd = Dir.pwd

    raise 'Configuration name is required' if name.nil?

    args = name.split('/')

    # mdbci box
    if File.exist?(args[0]+'/mdbci_template')
      $session.loadMdbciNodes args[0]
      if args[1].nil?     # read ip for all nodes
        raise "MDBCI nodes are not found in #{args[0]}" if $session.mdbciNodes.empty?
        $session.mdbciNodes.each do |node|
          box = node[1]['box'].to_s
          if !box.empty?
            box_params = $session.boxes.getBox(box)
            $out.info 'Node: ' + node[0].to_s
            $out.out box_params['IP'].to_s
          else
            raise "Can not find box parameter for node #{args[0]}"
          end
        end
      else
        mdbci_node = $session.mdbciNodes.find { |elem| elem[0].to_s == args[1] }
        raise "MDBCI node #{args[1]} is not found in #{args[0]}" if mdbci_node.nil?
        box = mdbci_node[1]['box'].to_s
        raise "Can not find box parameter for node #{args[1]}" if !box.empty?
        mdbci_params = $session.boxes.getBox(box)
        raise "Can not find box #{box} node #{args[1]} in #{args[0]}" if !box.empty?
        $out.info 'Node: ' + args[1].to_s
        $out.out mdbci_params['IP'].to_s

      end
    else # aws, vbox nodes
      raise "Can not find directory #{args[0]}" unless Dir.exists? args[0]
      network = Network.new
      network.loadNodes pwd.to_s+'/'+args[0] # load nodes from dir
      if args[1].nil? # No node argument, show all config
        raise "Nodes are not found in #{args[0]}" if network.nodes.empty?
        network.nodes.each do |node|
          exit_code = node.getIp(node.provider, true)
          raise "Can not get IP for #{node.name} in #{args[0]}" if exit_code != 0
          $out.info 'Node: ' + node.name
          $out.out node.ip.to_s
        end
      else
        node = network.nodes.find { |elem| elem.name == args[1]}
        raise "Node #{args[1]} is not found in #{args[0]}" if node.nil?
        exit_code = node.getIp(node.provider, true)
        raise "Can not get IP for #{node.name} in #{args[0]}" if exit_code != 0
        $out.info 'Node: ' + node.name
        $out.out node.ip.to_s
      end
    end
    Dir.chdir pwd

    return 0
  end

end

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

    if name.nil?
      $out.error 'Configuration name is required'
      return
    end

    args = name.split('/')

    # mdbci ppc64 boxes
    if File.exist?(args[0]+'/mdbci_template')
      $session.loadMdbciNodes args[0]
      if args[1].nil?
        $session.mdbciNodes.each do |node|
          box = node[1]['box'].to_s
          box_params = $session.boxes.getBox(box)
          $out.info 'Node: ' + node[0].to_s
          if File.exist?(pwd+'/KEYS/'+box_params['keyfile'].to_s) 
            $out.out pwd+'/KEYS/'+box_params['keyfile'].to_s
          else
            $out.warning box_params['keyfile'].to_s+" not found!"
          end
        end
      else
        if $session.mdbciNodes.has_key?(args[1])
          mdbci_node = $session.mdbciNodes.find { |elem| elem[0].to_s == args[1] }
          box = mdbci_node[1]['box'].to_s
          mdbci_params = $session.boxes.getBox(box)
          $out.info 'Node: ' + args[1].to_s
          if File.exist?(pwd+'/KEYS/'+mdbci_params['keyfile'].to_s) 
            $out.out pwd+'/KEYS/'+mdbci_params['keyfile'].to_s
          else
            $out.warning mdbci_params['keyfile'].to_s+" not found!"
          end
        else
          $out.warning args[1].to_s+" mdbci node not found!"
        end
      end
    else
      Dir.chdir pwd.to_s+'/'+args[0]

      cmd = 'vagrant ssh-config '+args[1].to_s+ ' | grep IdentityFile '
      vagrant_out = `#{cmd}`
      $out.out vagrant_out.split(' ')[1]

      Dir.chdir pwd
    end
  end

  def self.show(name)

    pwd = Dir.pwd

    if name.nil?
      $out.error 'Configuration name is required'
      return 1
    end

    args = name.split('/')

    # mdbci ppc64 boxes
    if File.exist?(args[0]+'/mdbci_template')
      $session.loadMdbciNodes args[0]
      if args[1].nil?
        if $session.mdbciNodes.empty?
          $out.error "Nodes not found in #{args[0]}"
          return 1
        end
        $session.mdbciNodes.each do |node|
          box = node[1]['box'].to_s
          if !box.empty?
            box_params = $session.boxes.getBox(box)
            $out.info 'Node: ' + node[0].to_s
            $out.out box_params['IP'].to_s
          end
        end
      else
        mdbci_node = $session.mdbciNodes.find { |elem| elem[0].to_s == args[1] }
        if mdbci_node == nil
          return 1
        end
        box = mdbci_node[1]['box'].to_s
        if !box.empty?
          mdbci_params = $session.boxes.getBox(box)
          $out.info 'Node: ' + args[1].to_s
          $out.out mdbci_params['IP'].to_s
        else
          $out.error "Can not read parameter 'box' of node #{args[1]}"
          return 1
        end
      end
    else # aws, vbox nodes

      unless Dir.exists? args[0]
        $out.error "Configuration not found: #{args[0]}"
        return 1
      end

      network = Network.new
      network.loadNodes pwd.to_s+'/'+args[0] # load nodes from dir

      if args[1].nil? # No node argument, show all config
        network.nodes.each do |node|
          node.getIp(node.provider, false)
          $out.out node.ip.to_s
        end
      else
        node = network.nodes.find { |elem| elem.name == args[1]}
        node.getIp(node.provider, false)
        $out.out node.ip.to_s
      end
    end

    Dir.chdir pwd

    return 0

  end

  # TODO - move mdbci box definition to new class - MdbciNode < Node
  def self.private_ip(name)

    pwd = Dir.pwd

    if name.nil?
      $out.error 'Configuration name is required'
      return
    end

    args = name.split('/')

    # mdbci box
    if File.exist?(args[0]+'/mdbci_template')
      $session.loadMdbciNodes args[0]
      if args[1].nil?     # read ip for all nodes
        $session.mdbciNodes.each do |node|
          box = node[1]['box'].to_s
          if !box.empty?
            box_params = $session.boxes.getBox(box)
            $out.info 'Node: ' + node[0].to_s
            $out.out box_params['IP'].to_s
          end
        end
      else
        mdbci_node = $session.mdbciNodes.find { |elem| elem[0].to_s == args[1] }
        box = mdbci_node[1]['box'].to_s
        if !box.empty?
          mdbci_params = $session.boxes.getBox(box)
          $out.info 'Node: ' + args[1].to_s
          $out.out mdbci_params['IP'].to_s
        end
      end
    else # aws, vbox nodes
      network = Network.new
      network.loadNodes pwd.to_s+'/'+args[0] # load nodes from dir

      if args[1].nil? # No node argument, show all config
        network.nodes.each do |node|
          node.getIp(node.provider, true)
          $out.out node.ip.to_s
        end
      else
        node = network.nodes.find { |elem| elem.name == args[1]}
        node.getIp(node.provider, true)
        $out.out node.ip.to_s
      end
    end

    Dir.chdir pwd
  end

end

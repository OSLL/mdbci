require_relative  'node'
require_relative  '../core/out'

class Network

  attr_accessor :nodes

  def initialize
    @nodes = Array.new
  end

  def getNodeInfo(config, node)
    node = Node.new(config, node)
    @nodes.push(node)
  end

  def loadNodes(config)
    $out.info 'Load configuration nodes from vagrant status ...'

    Dir.chdir config

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
    provider = ["virtualbox", "aws", "mdbci"]
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

    if name.nil?
      $out.error 'Configuration name is required'
      return
    end

    args = name.split('/')

    pwd = Dir.pwd
    Dir.chdir args[0]

    cmd = 'vagrant ssh-config '+args[1]+ ' |grep IdentityFile '
    vagrant_out = `#{cmd}`

    $out.out vagrant_out.split(' ')[1]

    Dir.chdir pwd
  end

  def self.show(name)

    pwd = Dir.pwd

    if name.nil?
      $out.error 'Configuration name is required'
      return
    end

    args = name.split('/')

    network = Network.new
    network.loadNodes args[0] # load nodes from dir

    if args[1].nil? # No node argument, show all config
      network.nodes.each do |node|
        node.getIp(node.provider)
        $out.out(node.ip.to_s)
      end
    else
      node = network.nodes.find { |elem| elem.name == args[1]}
      node.getIp(node.provider)
      $out.out(node.ip.to_s)
    end

    Dir.chdir pwd
  end
end
require_relative  'node'
require_relative  '../core/out'

class Network

  attr_accessor :nodes

  def initialize
    @nodes = Array.new
  end

  def getNodeInfo(config, node)
    node = Node.new(config, node)
    $out.info 'Node: '+node.to_s
    @nodes.push(node)
  end

  def loadNodes(config)
    pwd = Dir.pwd
    Dir.chdir config

    vagrant_out = `vagrant status`

    $out.info '[[[[['+vagrant_out+']]]]]'

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

  Node info is located in (2..END-3) lines

=end

    (2..list.length-5).each do |x|
      getNodeInfo(config, list[x])
    end

    Dir.chdir pwd
  end

  def self.show(name)

      if name.nil?
        $out.info 'ERR: Configuration name is required'
        return
      end

      args = name.split('/')

      network = Network.new
      network.loadNodes args[0]

      if args[1].nil? # No node argument, show all config
        network.nodes.each do |node|
          $out.out node.ip + ' ' + node.name
        end
      else
        node = network.nodes.find {|name| name.name == args[1]}
        $out.out node.ip
      end

      $out.info args[1]
  end
end
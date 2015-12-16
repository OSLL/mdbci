require 'scanf'
require 'yaml'

require_relative  '../core/out'
require_relative '../core/network'


class NodeProduct


  #
  # Get product key
  def getProductKey(name)

  end
  #
  # Get product repo
  def getProductRepo(name)

  end



  #
  # Install repo for product to nodes
  #
  # Получать repo & repo_key из RepoManager repo.d
  # потом устанавливать в зависимости от платформы
  def self.installProductRepo(args)

    pwd = Dir.pwd

    if args.nil?
      $out.error 'Configuration name is required'
      return
    end

    args = args.split('/')

    # mdbci box
    if File.exist?(args[0]+'/mdbci_template')
      $session.loadMdbciNodes args[0]
      if args[1].nil?     # read ip for all nodes
        $session.mdbciNodes.each do |node|
          box = node[1]['box'].to_s
          if !box.empty?
            mdbci_params = $session.boxes[box]  # TODO: 6576
            #

            # get OS platform and version
            # get product repo and repo_key
            # create command for adding repo_key and repo for varios OS

            command = 'echo \''+keyfile_content+'\' >> /home/'+mdbci_params['user']+'/.ssh/authorized_keys'
            cmd = 'ssh -i ' + pwd.to_s+'/KEYS/'+mdbci_params['keyfile'].to_s + " "\
                            + mdbci_params['user'].to_s + "@"\
                            + mdbci_params['IP'].to_s + " "\
                            + "'" + command + "'"
            $out.info 'Copy '+@keyFile.to_s+' to '+node.name.to_s+'.'
            vagrant_out = `#{cmd}`
            $out.out vagrant_out
          end
        end
      else
        mdbci_node = @mdbciNodes.find { |elem| elem[0].to_s == args[1] }
        box = mdbci_node[1]['box'].to_s
        if !box.empty?
          mdbci_params = $session.boxes[box]
          #

          # TODO

          command = 'echo \''+keyfile_content+'\' >> /home/'+mdbci_params['user']+'/.ssh/authorized_keys'
          cmd = 'ssh -i ' + pwd.to_s+'/KEYS/'+mdbci_params['keyfile'].to_s + " "\
                          + mdbci_params['user'].to_s + "@"\
                          + mdbci_params['IP'].to_s + " "\
                          + "'" + command + "'"
          $out.info 'Copy '+@keyFile.to_s+' to '+mdbci_node[0].to_s+'.'
          vagrant_out = `#{cmd}`
          $out.out vagrant_out
        end
      end
    else # aws, vbox, libvirt, docker nodes
      network = Network.new
      network.loadNodes args[0] # load nodes from dir
      p network.nodes.to_s

      if args[1].nil? # No node argument, copy keys to all nodes
        network.nodes.each do |node|
          #
          # TODO

          $out.info 'Copy '+@keyFile.to_s+' to '+node.name.to_s+'.'
          vagrant_out = `#{cmd}`
          $out.out vagrant_out
        end
      else
        node = network.nodes.find { |elem| elem.name == args[1]}
        #
        # TODO

        $out.info 'Copy '+@keyFile.to_s+' to '+node.name.to_s+'.'
        vagrant_out = `#{cmd}`
        $out.out vagrant_out
      end
    end

    Dir.chdir pwd
  end


end
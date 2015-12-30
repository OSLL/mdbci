require 'scanf'
require 'yaml'

require_relative  '../core/out'


class NodeProduct
  #
  # 
  def getProductName(product)

    repoName = nil

    if !product['repo'].nil?
      repoName = product['repo']
      unless $session.repos.knownRepo?(repoName)
        $out.warning 'Unknown key for repo '+repoName.to_s+' will be skipped'
        return "#NONE, due invalid repo name \n"
      end
      product_name = $session.repos.productName(repoName)
    else
      product_name = product['name']
    end
    return product_name
  end
  #
  #
  def self.getProductRepoParameters(product, box)

    repo = nil
    repoName = nil

    if !product['repo'].nil?
      repoName = product['repo']
      unless $session.repos.knownRepo?(repoName)
        $out.warning 'Unknown key for repo '+repoName.to_s+' will be skipped'
        return "#NONE, due invalid repo name \n"
      end
      repo = $session.repos.getRepo(repoName)
      product_name = $session.repos.productName(repoName)
    else
      product_name = product['name']
    end

    if repo.nil?; repo = $session.repos.findRepo(product_name, product, box); end
    if repo.nil?; return nil; end
    
    return repo
  end
  #
  #
  def getProductRepoParametersByName(product_name, product, box)
    repo = $session.repos.findRepo(product_name, product, box)
    if repo.nil?; return nil; end
    return repo
  end
  #
  #         COMMANDS
  #
  # Install repo for product to nodes
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
	          # TODO
            # get OS platform and version
	          # get installed product
            # get product repo and repo_key
            # create command for adding repo_key and repo for varios OS
 	          #
	          #command = 'echo \''+keyfile_content+'\' >> /home/'+mdbci_params['user']+'/.ssh/authorized_keys'
            #cmd = 'ssh -i ' + pwd.to_s+'/KEYS/'+mdbci_params['keyfile'].to_s + " "\
            #                + mdbci_params['user'].to_s + "@"\
            #                + mdbci_params['IP'].to_s + " "\
            #                + "'" + command + "'"
            #$out.info 'Copy '+@keyFile.to_s+' to '+node.name.to_s+'.'
            #vagrant_out = `#{cmd}`
          end
        end
      else
        mdbci_node = $session.mdbciNodes.find { |elem| elem[0].to_s == args[1] }
        box = mdbci_node[1]['box'].to_s
        if !box.empty?
          mdbci_params = $session.boxes[box]  # TODO: 6576
          #
          # TODO
          #command = 'echo \''+keyfile_content+'\' >> /home/'+mdbci_params['user']+'/.ssh/authorized_keys'
          #cmd = 'ssh -i ' + pwd.to_s+'/KEYS/'+mdbci_params['keyfile'].to_s + " "\
          #                + mdbci_params['user'].to_s + "@"\
          #                + mdbci_params['IP'].to_s + " "\
          #                + "'" + command + "'"
          #$out.info 'Copy '+@keyFile.to_s+' to '+mdbci_node[0].to_s+'.'
          #vagrant_out = `#{cmd}`
        end
      end
    else # aws, vbox, libvirt, docker nodes
      Dir.chdir args[0]
      $session.loadTemplateNodes
      if args[1].nil? # No node argument, copy keys to all nodes
        $session.templateNodes.each do |node|
          repo = getProductRepoParameters(node[1]['product'], node[1]['box'])
          if !repo.nil?
            platform = $session.loadNodePlatformBy(node[0].to_s)
            $out.info 'Install '+$session.nodeProduct.to_s+' repo to '+platform.to_s+' platform.'
            if $session.nodeProduct == 'maxscale'
              cmd = createMaxscaleInstallRepoCmd(platform, node[0], repo)
              vagrant_out = `#{cmd}`
              exit_code = 0
            elsif $session.nodeProduct == 'mariadb'
              # TODO
              exit_code = 0
            elsif $session.nodeProduct == 'galera'
              # TODO
              exit_code = 0
            else
              $out.info 'Install repo: Unknown product!'
              exit_code = 1
            end
 	        else
	          $out.error 'No such product for this node!'
            exit_code = 1
          end
        end
      else
        node = $session.templateNodes.find { |elem| elem[0].to_s == args[1] }
        repo = getProductRepoParameters(node[1]['product'], node[1]['box'])
        if !repo.nil?
          platform = $session.loadNodePlatformBy(node[0].to_s)
          $out.info 'Install '+$session.nodeProduct.to_s+' repo on '+platform.to_s+' platform.'
          if $session.nodeProduct == 'maxscale'
            cmd = createMaxscaleInstallRepoCmd(platform, node[0].to_s, repo)
	          vagrant_out = `#{cmd}`
            exit_code = 0
          elsif $session.nodeProduct == 'mariadb'
            # TODO
            exit_code = 0
          elsif $session.nodeProduct == 'galera'
            # TODO
            exit_code = 0
          else
            $out.info 'Install repo: Unknown product!'
            exit_code = 1
          end
        else
 	        $out.error 'No such product for this node!'
          exit_code = 1
        end
      end
    end

    Dir.chdir pwd
    return exit_code
  end
  #
  # install maxscale command
  def self.createMaxscaleInstallRepoCmd(platform, node_name, repo)
    if platform == 'ubuntu' || platform == 'debian'
      cmd_install_repo = 'vagrant ssh '+node_name+' -c "sudo apt-key adv --recv-keys --keyserver keyserver.ubuntu.com '+repo['repo_key']+' && '\
                       + 'sudo dd if=/dev/null of=/etc/apt/sources.list.d/maxscale.list && '\
		       + 'sudo echo -e \"deb '+repo['repo']+'\" | sudo tee -a /etc/apt/sources.list.d/maxscale.list"'
    elsif platform == 'rhel' || platform == 'centos' || platform == 'fedora'
      cmd_install_repo = 'vagrant ssh '+node_name+' -c "sudo dd if=/dev/null of=/etc/yum.repos.d/maxscale.repo && '\
		       + 'sudo echo -e \"[maxscale]'+'\n'+'name=maxscale'+'\n'+'baseurl='+repo['repo']+'\n'+'gpgkey='+repo['repo_key']+'\n'+'gpgcheck=1\" | sudo tee -a /etc/yum.repos.d/maxscale.repo"'
    elsif platform == 'sles' || platform == 'suse' || platform == 'opensuse'
      cmd_install_repo = 'vagrant ssh '+node_name+' -c "sudo dd if=/dev/null of=/etc/zypp/repos.d/maxscale.repo && '\
		       + 'sudo echo -e \"[maxscale]'+'\n'+'name=maxscale'+'\n'+'baseurl='+repo['repo']+'\n'+'gpgkey='+repo['repo_key']+'\n'+'gpgcheck=1\" | sudo tee -a /etc/zypp/repos.d/maxscale.repo"'
    end
    return cmd_install_repo
  end
  #
  # TODO: create single function for install and update cmd, by different mdbci cmd! 
  #
  # Update repo for product to nodes
  def self.updateProductRepo(args)

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
            # TODO
            #command = 'echo \''+keyfile_content+'\' >> /home/'+mdbci_params['user']+'/.ssh/authorized_keys'
            #cmd = 'ssh -i ' + pwd.to_s+'/KEYS/'+mdbci_params['keyfile'].to_s + " "\
            #                + mdbci_params['user'].to_s + "@"\
            #                + mdbci_params['IP'].to_s + " "\
            #                + "'" + command + "'"
            #$out.info 'Copy '+@keyFile.to_s+' to '+node.name.to_s+'.'
            #vagrant_out = `#{cmd}`
          end
        end
      else
        mdbci_node = $session.mdbciNodes.find { |elem| elem[0].to_s == args[1] }
        box = mdbci_node[1]['box'].to_s
        if !box.empty?
          mdbci_params = $session.boxes[box]  # TODO: 6576
          #
          # TODO
          #command = 'echo \''+keyfile_content+'\' >> /home/'+mdbci_params['user']+'/.ssh/authorized_keys'
          #cmd = 'ssh -i ' + pwd.to_s+'/KEYS/'+mdbci_params['keyfile'].to_s + " "\
          #                + mdbci_params['user'].to_s + "@"\
          #                + mdbci_params['IP'].to_s + " "\
          #                + "'" + command + "'"
          #$out.info 'Copy '+@keyFile.to_s+' to '+mdbci_node[0].to_s+'.'
          #vagrant_out = `#{cmd}`
        end
      end
    else # aws, vbox, libvirt, docker nodes
      Dir.chdir args[0]
      $session.loadTemplateNodes
      if args[1].nil? # No node argument, copy keys to all nodes
        $session.templateNodes.each do |node|
          platform = $session.loadNodePlatformBy(node[0].to_s)
          $out.info 'Update '+$session.nodeProduct.to_s+' repo on '+platform.to_s+' platform.'
          if $session.nodeProduct == 'maxscale'
            cmd = createMaxscaleUpdateRepoCmd(platform, node[0])
            vagrant_out = `#{cmd}`
	          #cmd_out = vagrant_out.split('\r\r')
            exit_code = 0
          elsif $session.nodeProduct == 'mariadb'
            # TODO
            exit_code = 0
          elsif $session.nodeProduct == 'galera'
            # TODO
            exit_code = 0
          else
            $out.info 'Update repo: Unknown product!'
            exit_code = 1
          end
        end
      else
        node = $session.templateNodes.find { |elem| elem[0].to_s == args[1] }
        platform = $session.loadNodePlatformBy(node[0].to_s)
        $out.info 'Update '+$session.nodeProduct.to_s+' repo on '+platform.to_s+' platform.'
        if $session.nodeProduct == 'maxscale'
          cmd = createMaxscaleUpdateRepoCmd(platform, node[0].to_s)
          vagrant_out = `#{cmd}`
          exit_code = 0
        elsif $session.nodeProduct == 'mariadb'
          # TODO
          exit_code = 0
        elsif $session.nodeProduct == 'galera'
          # TODO
          exit_code = 0
        else
          $out.info 'Update repo: Unknown product!'
          exit_code = 1
        end
      end
    end
    Dir.chdir pwd
    return exit_code
  end
  #
  # update maxscale command
  def self.createMaxscaleUpdateRepoCmd(platform, node_name)
    if platform == 'ubuntu' || platform == 'debian'
      cmd_update_repo = 'vagrant ssh '+node_name+' -c "sudo apt-get --only-upgrade true install maxscale"'
    elsif platform == 'rhel' || platform == 'centos' || platform == 'fedora'
      cmd_update_repo = 'vagrant ssh '+node_name+' -c "sudo yum update maxscale"'
    elsif platform == 'sles' || platform == 'suse' || platform == 'opensuse'
      cmd_update_repo = 'vagrant ssh '+node_name+' -c "sudo zypper up maxscale"'
    end
    return cmd_update_repo
  end

end

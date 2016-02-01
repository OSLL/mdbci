require 'scanf'
require 'yaml'
require 'shellwords'

require_relative  '../core/out'


class NodeProduct
  #
  #
  def getProductRepoParameters(product, box)

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
  def getMaxscaleRepoByBox(box)

    product_name = 'maxscale'
    version = 'default'
    platform = $session.platformKey(box)

    repokey = product_name+'@'+version+'+'+ platform
    repo = $session.repos.getRepo(repokey)
    $out.info 'Repo key is '+repokey + ' ... ' + (repo.nil? ? 'NOT_FOUND' : 'FOUND')

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
  # Setup repo for product to nodes (install product repo and update it)
  # Supported products: Maxscale
  #
  # P.S. Require to add NOPASSWD:ALL to /etc/sudoers for a mdbci node user!
  # for example, vagranttest ALL=(ALL) NOPASSWD:ALL
  #
  # TODO - get repo for mariadb, galera, mysql
  # TODO - Where to store product version for mdbci boxes? In boxes.json node or another place?
  def self.setupProductRepo(args)

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
            mdbci_params = $session.boxes.getBox(box)
 	          #
            platform = $session.platformKey(box).split('^')
            $out.info 'Install '+$session.nodeProduct.to_s+' repo to '+platform.to_s
            if $session.nodeProduct == 'maxscale'
              repo = getMaxscaleRepoByBox(box)
              if !repo.nil?
                # # { ssh ... } version
                command = maxscaleMdbciSetupRepoCmd(platform[0], repo)
                cmd = 'ssh -i ' + pwd.to_s+'/KEYS/'+mdbci_params['keyfile'].to_s + ' '\
                              + mdbci_params['user'].to_s + '@'\
                              + mdbci_params['IP'].to_s + ' '\
                              + "'" + command.to_s + "'"
                $out.info 'Running ['+cmd+'] on '+args[0].to_s+'/'+args[1].to_s
                vagrant_out = `#{cmd}`
                $out.out vagrant_out
              end
            elsif $session.nodeProduct == 'mariadb'
              # TODO
            elsif $session.nodeProduct == 'galera'
              # TODO
            else
              $out.info 'Install repo: Unknown product!'
            end
          end
        end
      else
        mdbci_node = $session.mdbciNodes.find { |elem| elem[0].to_s == args[1] }
        box = mdbci_node[1]['box'].to_s
        if !box.empty?
          mdbci_params = $session.boxes.getBox(box)
          platform = $session.platformKey(box).split('^')
          $out.info 'Install '+$session.nodeProduct.to_s+' repo to '+platform.to_s
          if $session.nodeProduct == 'maxscale'
            repo = getMaxscaleRepoByBox(box)
            if !repo.nil?
              command = maxscaleMdbciSetupRepoCmd(platform[0], repo)
              cmd = 'ssh -i ' + pwd.to_s+'/KEYS/'+mdbci_params['keyfile'].to_s + ' '\
                              + mdbci_params['user'].to_s + '@'\
                              + mdbci_params['IP'].to_s + ' '\
                              + "'" + command + "'"
              $out.info 'Running ['+cmd+'] on '+args[0].to_s+'/'+args[1].to_s
              vagrant_out = `#{cmd}`
              $out.out vagrant_out
            end
          elsif $session.nodeProduct == 'mariadb'
            # TODO
          elsif $session.nodeProduct == 'galera'
            # TODO
          else
            $out.info 'Install repo: Unknown product!'
          end
        end
      end
    else # aws, vbox, libvirt, docker nodes
      Dir.chdir args[0]
      $session.loadTemplateNodes
      if args[1].nil? # No node argument, copy keys to all nodes
        $session.templateNodes.each do |node|
          repo = getProductRepoParameters(node[1]['product'], node[1]['box'])
          if !repo.nil?
            platform = $session.loadNodePlatform(node[0].to_s)
            $out.info 'Install '+$session.nodeProduct.to_s+' repo to '+platform.to_s
            if $session.nodeProduct == 'maxscale'
              cmd = maxscaleSetupRepoCmd(platform, node[0], repo)
              vagrant_out = `#{cmd}`
              $out.out vagrant_out
            elsif $session.nodeProduct == 'mariadb'
              # TODO
            elsif $session.nodeProduct == 'galera'
              # TODO
            else
              $out.info 'Install repo: Unknown product!'
            end
 	        else
	          $out.error 'No such product for this node!'
          end
        end
      else
        node = $session.templateNodes.find { |elem| elem[0].to_s == args[1] }
        repo = getProductRepoParameters(node[1]['product'], node[1]['box'])
        if !repo.nil?
          platform = $session.loadNodePlatform(node[0].to_s)
          $out.info 'Install '+$session.nodeProduct.to_s+' repo to '+platform.to_s
          if $session.nodeProduct == 'maxscale'
            cmd = maxscaleSetupRepoCmd(platform, node[0].to_s, repo)
	          vagrant_out = `#{cmd}`
            $out.out vagrant_out
          elsif $session.nodeProduct == 'mariadb'
            # TODO
          elsif $session.nodeProduct == 'galera'
            # TODO
          else
            $out.info 'Install repo: Unknown product!'
          end
        else
 	        $out.error 'No such product for this node!'
        end
      end
    end

    Dir.chdir pwd
  end

  def maxscaleSetupRepoCmd(platform, node_name, repo)
    if platform == 'ubuntu' || platform == 'debian'
      cmd_install_repo = 'vagrant ssh '+node_name+' -c "sudo apt-key adv --recv-keys --keyserver keyserver.ubuntu.com '+Shellwords.escape(repo['repo_key'].to_s)+' && '\
                       + 'sudo dd if=/dev/null of=/etc/apt/sources.list.d/maxscale.list && '\
		                   + 'sudo echo -e \'deb '+Shellwords.escape(repo['repo'].to_s)+'\' | sudo tee -a /etc/apt/sources.list.d/maxscale.list && '\
		                   + 'sudo apt-get --only-upgrade true install maxscale"'
    elsif platform == 'rhel' || platform == 'centos' || platform == 'fedora'
      cmd_install_repo = 'vagrant ssh '+node_name+' -c "sudo dd if=/dev/null of=/etc/yum.repos.d/maxscale.repo && '\
		                   + 'sudo echo -e \'[maxscale]'+'\n'+'name=maxscale'+'\n'+'baseurl='+Shellwords.escape(repo['repo'].to_s)+'\n'\
		                   + 'gpgkey='+Shellwords.escape(repo['repo_key'].to_s)+'\n'\
		                   + 'gpgcheck=1\' | sudo tee -a /etc/yum.repos.d/maxscale.repo && '\
		                   + 'sudo yum clean all && sudo sudo yum update maxscale"'
    elsif platform == 'sles' || platform == 'suse' || platform == 'opensuse'
      cmd_install_repo = 'vagrant ssh '+node_name+' -c "sudo dd if=/dev/null of=/etc/zypp/repos.d/maxscale.repo && '\
		                   + 'sudo echo -e \'[maxscale]'+'\n'+'name=maxscale'+'\n'+'baseurl='+Shellwords.escape(repo['repo'].to_s)+'\n'\
		                   + 'gpgkey='+Shellwords.escape(repo['repo_key'].to_s)+'\n'\
		                   + 'gpgcheck=1\' | sudo tee -a /etc/zypp/repos.d/maxscale.repo && '\
		                   + 'sudo zypper up maxscale"'
    end
    return cmd_install_repo
  end

  # for #{ ssh ... } version
  def maxscaleMdbciSetupRepoCmd(platform, repo)
    if platform == 'ubuntu' || platform == 'debian'
      cmd_install_repo = 'sudo apt-key adv --recv-keys --keyserver keyserver.ubuntu.com '+Shellwords.escape(repo['repo_key'].to_s)+' && '\
                       + 'sudo dd if=/dev/null of=/etc/apt/sources.list.d/maxscale.list && '\
		                   + 'sudo echo -e \'deb '+Shellwords.escape(repo['repo'].to_s)+'\' | sudo tee -a /etc/apt/sources.list.d/maxscale.list && '\
		                   + 'sudo apt-get --only-upgrade true install maxscale'
    elsif platform == 'rhel' || platform == 'centos' || platform == 'fedora'
      cmd_install_repo = 'sudo dd if=/dev/null of=/etc/yum.repos.d/maxscale.repo && '\
		                   + 'sudo echo -e \'[maxscale]'+'\n'+'name=maxscale'+'\n'+'baseurl='+Shellwords.escape(repo['repo'].to_s)+'\n'\
		                   + 'gpgkey='+Shellwords.escape(repo['repo_key'].to_s)+'\n'\
                       + 'gpgcheck=1\' | sudo tee -a /etc/yum.repos.d/maxscale.repo && '\
		                   + 'sudo yum clean all && sudo sudo yum update maxscale'
    elsif platform == 'sles' || platform == 'suse' || platform == 'opensuse'
      cmd_install_repo = 'sudo dd if=/dev/null of=/etc/zypp/repos.d/maxscale.repo && '\
		                   + 'sudo echo -e \'[maxscale]'+'\n'+'name=maxscale'+'\n'+'baseurl='+Shellwords.escape(repo['repo'].to_s)+'\n'\
		                   + 'gpgkey='+Shellwords.escape(repo['repo_key'].to_s)+'\n'\
                       + 'gpgcheck=1\' | sudo tee -a /etc/zypp/repos.d/maxscale.repo && '\
		                   + 'sudo zypper up maxscale'
    end
    return cmd_install_repo
  end
  #
  #
  # Install product command. Supported: Maxscale
  def self.installProduct(args)
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
            mdbci_params = $session.boxes.getBox(box)
            platform = $session.platformKey(box).split('^')
            $out.info 'Install '+$session.nodeProduct.to_s+' repo to '+platform.to_s
            if $session.nodeProduct == 'maxscale'
              # #{ ssh ... } version
              command = installMaxscaleProductMdbciCmd(platform[0])
              cmd = 'ssh -i ' + pwd.to_s+'/KEYS/'+mdbci_params['keyfile'].to_s + ' '\
                              + mdbci_params['user'].to_s + '@'\
                              + mdbci_params['IP'].to_s + ' '\
                              + "'" + command.to_s + "'"
              $out.info 'Running ['+cmd+'] on '+args[0].to_s+'/'+args[1].to_s
              vagrant_out = `#{cmd}`
              $out.out vagrant_out
            elsif $session.nodeProduct == 'mariadb'
              # TODO
            elsif $session.nodeProduct == 'galera'
              # TODO
            else
              $out.info 'Install product: Unknown product!'
            end
          end
        end
      else
        mdbci_node = $session.mdbciNodes.find { |elem| elem[0].to_s == args[1] }
        box = mdbci_node[1]['box'].to_s
        if !box.empty?
          mdbci_params = $session.boxes.getBox(box)
          platform = $session.platformKey(box).split('^')
          $out.info 'Install '+$session.nodeProduct.to_s+' product to '+platform.to_s
          if $session.nodeProduct == 'maxscale'
            command = installMaxscaleProductMdbciCmd(platform[0])
            cmd = 'ssh -i ' + pwd.to_s+'/KEYS/'+mdbci_params['keyfile'].to_s + ' '\
                            + mdbci_params['user'].to_s + '@'\
                            + mdbci_params['IP'].to_s + ' '\
                            + "'" + command + "'"
            $out.info 'Running ['+cmd+'] on '+args[0].to_s+'/'+args[1].to_s
            vagrant_out = `#{cmd}`
            $out.out vagrant_out
          elsif $session.nodeProduct == 'mariadb'
            # TODO
          elsif $session.nodeProduct == 'galera'
            # TODO
          else
            $out.info 'Install product: Unknown product!'
          end
        end
      end
    else # aws, vbox, libvirt, docker nodes
      Dir.chdir args[0]
      $session.loadTemplateNodes
      if args[1].nil? # No node argument, copy keys to all nodes
        $session.templateNodes.each do |node|
          platform = $session.loadNodePlatform(node[0].to_s)
          $out.info 'Install '+$session.nodeProduct.to_s+' product to '+platform.to_s
          if $session.nodeProduct == 'maxscale'
            cmd = installMaxscaleProductCmd(platform, node[0])
            vagrant_out = `#{cmd}`
          elsif $session.nodeProduct == 'mariadb'
            # TODO
          elsif $session.nodeProduct == 'galera'
            # TODO
          else
            $out.info 'Install product: Unknown product!'
          end
        end
      else
        node = $session.templateNodes.find { |elem| elem[0].to_s == args[1] }
        platform = $session.loadNodePlatform(node[0].to_s)
        $out.info 'Install '+$session.nodeProduct.to_s+' product to '+platform.to_s
        if $session.nodeProduct == 'maxscale'
          cmd = installMaxscaleProductCmd(platform, node[0].to_s)
          vagrant_out = `#{cmd}`
        elsif $session.nodeProduct == 'mariadb'
          # TODO
        elsif $session.nodeProduct == 'galera'
          # TODO
        else
          $out.info 'Install product: Unknown product!'
        end
      end
    end

    Dir.chdir pwd
  end

  # install Maxscale product command for Vagrant nodes
  def installMaxscaleProductCmd(platform, node_name)
    if platform == 'ubuntu' || platform == 'debian'
      cmd_update_repo = 'vagrant ssh '+node_name+' -c "sudo apt-get -y install maxscale"'
    elsif platform == 'rhel' || platform == 'centos' || platform == 'fedora'
      cmd_update_repo = 'vagrant ssh '+node_name+' -c "sudo yum -y install maxscale"'
    elsif platform == 'sles' || platform == 'suse' || platform == 'opensuse'
      cmd_update_repo = 'vagrant ssh '+node_name+' -c "sudo zypper --non-interactive install maxscale"'
    end
    return cmd_update_repo
  end
  #
  # #{ ssh ... } version of install Maxscale product on a mdbci nodes
  def installMaxscaleProductMdbciCmd(platform)
    if platform == 'ubuntu' || platform == 'debian'
      cmd_update_repo = 'sudo apt-get -y install maxscale'
    elsif platform == 'rhel' || platform == 'centos' || platform == 'fedora'
      cmd_update_repo = 'sudo yum -y install maxscale'
    elsif platform == 'sles' || platform == 'suse' || platform == 'opensuse'
      cmd_update_repo = 'sudo zypper --non-interactive install maxscale'
    end
    return cmd_update_repo
  end

end

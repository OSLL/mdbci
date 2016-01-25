require 'scanf'
require 'yaml'
require 'shellwords'

require_relative  '../core/out'


class NodeProduct
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
  def self.getMaxscaleRepoByBox(box)

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
            mdbci_params = $session.boxes.getBox(box)
            #
	          # TODO - get repo for mariadb, galera, mysql
            #  - Where to store product version for mdbci boxes? In boxes.json node description!
 	          #
            platform = $session.platformKey(box).split('^')
            $out.info 'Install '+$session.nodeProduct.to_s+' repo to '+platform.to_s
            case $session.nodeProduct
              when 'maxscale'
                repo = getMaxscaleRepoByBox(box)
                if !repo.nil?
                  # # { ssh ... } version
                  #  P.S. Add NOPASSWD:ALL for node ssh user, for example, vagranttest ALL=(ALL) NOPASSWD:ALL
                  command = maxscaleMdbciInstallRepoCmd(platform[0], repo)
                  cmd = 'ssh -i ' + pwd.to_s+'/KEYS/'+mdbci_params['keyfile'].to_s + ' '\
                                + mdbci_params['user'].to_s + '@'\
                                + mdbci_params['IP'].to_s + ' '\
                                + "'" + command.to_s + "'"
                  $out.info 'Running ['+cmd+'] on '+args[0].to_s+'/'+args[1].to_s
                  vagrant_out = `#{cmd}`
                  $out.out vagrant_out
                end
              when 'mariadb'
                # TODO
              when 'galera'
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
          case $session.nodeProduct
            when 'maxscale'
              repo = getMaxscaleRepoByBox(box)
              if !repo.nil?
                command = maxscaleMdbciInstallRepoCmd(platform[0], repo)
                cmd = 'ssh -i ' + pwd.to_s+'/KEYS/'+mdbci_params['keyfile'].to_s + ' '\
                                + mdbci_params['user'].to_s + '@'\
                                + mdbci_params['IP'].to_s + ' '\
                                + "'" + command + "'"
                $out.info 'Running ['+cmd+'] on '+args[0].to_s+'/'+args[1].to_s
                vagrant_out = `#{cmd}`
                $out.out vagrant_out
              end
            when 'mariadb'
              # TODO
            when 'galera'
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
            platform = $session.loadNodePlatformBy(node[0].to_s)
            $out.info 'Install '+$session.nodeProduct.to_s+' repo to '+platform.to_s
            case $session.nodeProduct
              when 'maxscale'
                cmd = maxscaleInstallRepoCmd(platform, node[0].to_s, repo)
                vagrant_out = `#{cmd}`
                $out.info vagrant_out.to_s
              when 'mariadb'
                # TODO
              when 'galera'
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
          platform = $session.loadNodePlatformBy(node[0].to_s)
          $out.info 'Install '+$session.nodeProduct.to_s+' repo to '+platform.to_s
          case $session.nodeProduct
            when 'maxscale'
              cmd = maxscaleInstallRepoCmd(platform, node[0].to_s, repo)
	            vagrant_out = `#{cmd}`
              $out.info vagrant_out.to_s
            when 'mariadb'
              # TODO
            when 'galera'
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
  #
  def self.maxscaleInstallRepoCmd(platform, node_name, repo)
    if platform == 'ubuntu' || platform == 'debian'
      cmd_install_repo = 'vagrant ssh '+node_name+' -c "sudo apt-key adv --recv-keys --keyserver keyserver.ubuntu.com '+Shellwords.escape(repo['repo_key'].to_s)+' && '\
                       + 'sudo dd if=/dev/null of=/etc/apt/sources.list.d/maxscale.list && '\
		                   + 'sudo echo -e \"deb '+Shellwords.escape(repo['repo'].to_s)+'\" | sudo tee -a /etc/apt/sources.list.d/maxscale.list"'
    elsif platform == 'rhel' || platform == 'centos' || platform == 'fedora'
      cmd_install_repo = 'vagrant ssh '+node_name+' -c "sudo dd if=/dev/null of=/etc/yum.repos.d/maxscale.repo && '\
		                   + 'sudo echo -e \'[maxscale]'+'\n'+'name=maxscale'+'\n'+'baseurl='+Shellwords.escape(repo['repo'].to_s)+'\n'\
		                   + 'gpgkey='+Shellwords.escape(repo['repo_key'].to_s)+'\n'\
		                   + 'gpgcheck=1\' | sudo tee -a /etc/yum.repos.d/maxscale.repo"'
    elsif platform == 'sles' || platform == 'suse' || platform == 'opensuse'
      cmd_install_repo = 'vagrant ssh '+node_name+' -c "sudo dd if=/dev/null of=/etc/zypp/repos.d/maxscale.repo && '\
		                   + 'sudo echo -e \'[maxscale]'+'\n'+'name=maxscale'+'\n'+'baseurl='+Shellwords.escape(repo['repo'].to_s)+'\n'\
		                   + 'gpgkey='+Shellwords.escape(repo['repo_key'].to_s)+'\n'\
		                   + 'gpgcheck=1\' | sudo tee -a /etc/zypp/repos.d/maxscale.repo"'
    end
    return cmd_install_repo
  end
  #
  # for #{ ssh ... } version
  def self.maxscaleMdbciInstallRepoCmd(platform, repo)
    if platform == 'ubuntu' || platform == 'debian'
      cmd_install_repo = 'sudo apt-key adv --recv-keys --keyserver keyserver.ubuntu.com '+Shellwords.escape(repo['repo_key'].to_s)+' && '\
                       + 'sudo dd if=/dev/null of=/etc/apt/sources.list.d/maxscale.list && '\
		                   + 'sudo echo -e deb '+Shellwords.escape(repo['repo'].to_s)+' | sudo tee -a /etc/apt/sources.list.d/maxscale.list'
    elsif platform == 'rhel' || platform == 'centos' || platform == 'fedora'
      cmd_install_repo = 'sudo dd if=/dev/null of=/etc/yum.repos.d/maxscale.repo && '\
		                   + 'sudo echo -e \'[maxscale]'+'\n'+'name=maxscale'+'\n'+'baseurl='+Shellwords.escape(repo['repo'].to_s)+'\n'\
		                   + 'gpgkey='+Shellwords.escape(repo['repo_key'].to_s)+'\n'\
                       + 'gpgcheck=1\' | sudo tee -a /etc/yum.repos.d/maxscale.repo'
    elsif platform == 'sles' || platform == 'suse' || platform == 'opensuse'
      cmd_install_repo = 'sudo dd if=/dev/null of=/etc/zypp/repos.d/maxscale.repo && '\
		                   + 'sudo echo -e \'[maxscale]'+'\n'+'name=maxscale'+'\n'+'baseurl='+Shellwords.escape(repo['repo'].to_s)+'\n'\
		                   + 'gpgkey='+Shellwords.escape(repo['repo_key'].to_s)+'\n'\
                       + 'gpgcheck=1\' | sudo tee -a /etc/zypp/repos.d/maxscale.repo'
    end
    return cmd_install_repo
  end
  #
  #
  # Update nodes product repo
  #  P.S. Add NOPASSWD:ALL for mdbci node ssh user, for example, vagranttest ALL=(ALL) NOPASSWD:ALL to /etc/sudoers
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
            mdbci_params = $session.boxes.getBox(box)
            platform = $session.platformKey(box).split('^')
            $out.info 'Install '+$session.nodeProduct.to_s+' repo to '+platform.to_s
            case $session.nodeProduct
              when 'maxscale'
                command = maxscaleMdbciUpdateRepoCmd(platform[0])
                cmd = 'ssh -i ' + pwd.to_s+'/KEYS/'+mdbci_params['keyfile'].to_s + ' '\
                            + mdbci_params['user'].to_s + '@'\
                            + mdbci_params['IP'].to_s + ' '\
                            + "'" + command + "'"
                $out.info 'Running ['+cmd+'] on '+args[0].to_s+'/'+args[1].to_s
                vagrant_out = `#{cmd}`
                $out.out vagrant_out
              when 'mariadb'
                # TODO
              when 'galera'
                # TODO
              else
                $out.warning 'Update repo: Unknown product!'
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
          case $session.nodeProduct
            when 'maxscale'
              command = maxscaleMdbciUpdateRepoCmd(platform[0])
              cmd = 'ssh -i ' + pwd.to_s+'/KEYS/'+mdbci_params['keyfile'].to_s + ' '\
                            + mdbci_params['user'].to_s + '@'\
                            + mdbci_params['IP'].to_s + ' '\
                            + "'" + command + "'"
              $out.info 'Running ['+cmd+'] on '+args[0].to_s+'/'+args[1].to_s
              vagrant_out = `#{cmd}`
              $out.out vagrant_out
            when 'mariadb'
              # TODO
            when 'galera'
              # TODO
            else
              $out.warning 'Update repo: Unknown product!'
          end
        end
      end
    else # aws, vbox, libvirt, docker nodes
      Dir.chdir args[0]
      $session.loadTemplateNodes
      if args[1].nil? # No node argument, copy keys to all nodes
        $session.templateNodes.each do |node|
          platform = $session.loadNodePlatformBy(node[0].to_s)
          $out.info 'Update '+$session.nodeProduct.to_s+' repo on '+platform.to_s+' platform.'
          case $session.nodeProduct
            when 'maxscale'
              cmd = maxscaleUpdateRepoCmd(platform, node[0])
              vagrant_out = `#{cmd}`
              $out.info vagrant_out.to_s
            when 'mariadb'
              # TODO
            when 'galera'
              # TODO
            else
              $out.info 'Update repo: Unknown product!'
          end
        end
      else
        node = $session.templateNodes.find { |elem| elem[0].to_s == args[1] }
        platform = $session.loadNodePlatformBy(node[0].to_s)
        $out.info 'Update '+$session.nodeProduct.to_s+' repo on '+platform.to_s+' platform.'
        case $session.nodeProduct
          when 'maxscale'
            cmd = maxscaleUpdateRepoCmd(platform, node[0])
            vagrant_out = `#{cmd}`
            $out.info vagrant_out.to_s
          when 'mariadb'
            # TODO
          when 'galera'
            # TODO
          else
            $out.info 'Update repo: Unknown product!'
        end
      end
    end
    Dir.chdir pwd
  end
  #
  # update maxscale command
  def self.maxscaleUpdateRepoCmd(platform, node_name)
    if platform == 'ubuntu' || platform == 'debian'
      cmd_update_repo = 'vagrant ssh '+node_name+' -c "sudo apt-get --only-upgrade true install maxscale"'
    elsif platform == 'rhel' || platform == 'centos' || platform == 'fedora'
      cmd_update_repo = 'vagrant ssh '+node_name+' -c "sudo yum update maxscale"'
    elsif platform == 'sles' || platform == 'suse' || platform == 'opensuse'
      cmd_update_repo = 'vagrant ssh '+node_name+' -c "sudo zypper up maxscale"'
    end
    return cmd_update_repo
  end
  #
  # for #{ ssh ... } version
  def self.maxscaleMdbciUpdateRepoCmd(platform)
    if platform == 'ubuntu' || platform == 'debian'
      cmd_update_repo = 'sudo apt-get --only-upgrade true install maxscale'
    elsif platform == 'rhel' || platform == 'centos' || platform == 'fedora'
      cmd_update_repo = 'sudo yum update maxscale'
    elsif platform == 'sles' || platform == 'suse' || platform == 'opensuse'
      cmd_update_repo = 'sudo zypper up maxscale'
    end
    return cmd_update_repo
  end

end

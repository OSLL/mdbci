require 'scanf'
require 'yaml'

require 'net/ssh'   # gem install net-ssh
require 'net/scp'   # gem install net-scp

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
            if $session.nodeProduct == 'maxscale'
              repo = getMaxscaleRepoByBox(box)
              if !repo.nil?
                # 1
                # create repo file for each os and download it to server
                # ssh sudo: https://irb.rocks/execute-sudo-commands-with-net-ssh
                # maxscaleMdbciNetScpCmd(pwd, platform[0], repo, mdbci_params)
                #
                # 2
                # # { ssh ... } version
                #  P.S. Add NOPASSWD:ALL for node ssh user !
                command = maxscaleMdbciInstallRepoCmd(platform[0], repo)
                cmd = 'ssh -i ' + pwd.to_s+'/KEYS/'+mdbci_params['keyfile'].to_s + ' '\
                              + mdbci_params['user'].to_s + '@'\
                              + mdbci_params['IP'].to_s + ' '\
                              + "'" + command.to_s + "'"
                $out.info 'Running ['+cmd+'] on '+args[0].to_s+'/'+args[1].to_s
                vagrant_out = `#{cmd}`
                $out.out vagrant_out
                #
                # 3
                # # { scp ... } version
                #   - P.S. Need root password or key for access to /
                # createMaxscaleRepoFileMdbciScp(pwd, platform[0], repo)
                # remotepath = ''
                #if platform == 'ubuntu' || platform == 'debian'
                #  remotepath = '/etc/apt/sources.list.d'
                #end
                #cmd = 'scp -i ' + pwd.to_s+'/KEYS/'+mdbci_params['keyfile'].to_s + ' '\
                #                + pwd.to_s+'/maxscale.list '\
                #                + mdbci_params['user'].to_s + '@'\
                #                + mdbci_params['IP'].to_s + ':'\
                #                + remotepath.to_s
                #$out.info 'Running ['+cmd+'] on '+args[0].to_s+'/'+args[1].to_s
                #vagrant_out = `#{cmd}`
                #$out.out vagrant_out
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
              command = maxscaleMdbciInstallRepoCmd(platform[0], repo)
              cmd = 'ssh -i ' + pwd.to_s+'/KEYS/'+mdbci_params['keyfile'].to_s + ' '\
                              + mdbci_params['user'].to_s + '@'\
                              + mdbci_params['IP'].to_s + ' '\
                              + "'" + command + "'"
              $out.info 'Running ['+cmd+'] on '+args[0].to_s+'/'+args[1].to_s
              vagrant_out = `#{cmd}`
              #$out.out vagrant_out
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
            platform = $session.loadNodePlatformBy(node[0].to_s)
            $out.info 'Install '+$session.nodeProduct.to_s+' repo to '+platform.to_s
            if $session.nodeProduct == 'maxscale'
              cmd = maxscaleInstallRepoCmd(platform, node[0], repo)
              vagrant_out = `#{cmd}`
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
          platform = $session.loadNodePlatformBy(node[0].to_s)
          $out.info 'Install '+$session.nodeProduct.to_s+' repo to '+platform.to_s
          if $session.nodeProduct == 'maxscale'
            cmd = maxscaleInstallRepoCmd(platform, node[0].to_s, repo)
	          vagrant_out = `#{cmd}`
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

  def self.maxscaleInstallRepoCmd(platform, node_name, repo)
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

  # for #{ ssh ... } version
  def self.maxscaleMdbciInstallRepoCmd(platform, repo)
    if platform == 'ubuntu' || platform == 'debian'
      cmd_install_repo = 'sudo dd if=/dev/null of=/etc/apt/sources.list.d/maxscale.list && '\
		                   + 'sudo echo -e \"deb '+repo['repo']+'\" | sudo tee -a /etc/apt/sources.list.d/maxscale.list'
    elsif platform == 'rhel' || platform == 'centos' || platform == 'fedora'
      cmd_install_repo = 'sudo dd if=/dev/null of=/etc/yum.repos.d/maxscale.repo && '\
		                   + 'sudo echo -e \"[maxscale]'+'\n'+'name=maxscale'+'\n'+'baseurl='+repo['repo']+'\n'+'gpgkey='+repo['repo_key']+'\n'
                       + 'gpgcheck=1\" | sudo tee -a /etc/yum.repos.d/maxscale.repo'
    elsif platform == 'sles' || platform == 'suse' || platform == 'opensuse'
      cmd_install_repo = 'sudo dd if=/dev/null of=/etc/zypp/repos.d/maxscale.repo && '\
		                   + 'sudo echo -e \"[maxscale]'+'\n'+'name=maxscale'+'\n'+'baseurl='+repo['repo']+'\n'+'gpgkey='+repo['repo_key']+'\n'
                       + 'gpgcheck=1\" | sudo tee -a /etc/zypp/repos.d/maxscale.repo'
    end
    return cmd_install_repo
  end

  # for net-scp version
  def self.createMaxscaleRepoFileMdbciScp(dir, platform, repo)

    if platform == 'ubuntu' || platform == 'debian'
      debrepofile = File.open(dir+'/maxscale.list', 'w')
      debrepofile.puts 'deb '+repo['repo']
      debrepofile.close
    elsif platform == 'rhel' || platform == 'centos' || platform == 'fedora'
      rhelrepofile = File.open(dir+'/maxscale.repo', 'w')
      rhelrepofile.puts '[maxscale]'+'\n'+'name=maxscale'+'\n'+'baseurl='+repo['repo']+'\n'+'gpgkey='+repo['repo_key']+'\n'+ 'gpgcheck=1'
      rhelrepofile.close
    elsif platform == 'sles' || platform == 'suse' || platform == 'opensuse'
      slesrepofile = File.open(dir+'/maxscale.repo', 'w')
      slesrepofile.puts = '[maxscale]'+'\n'+'name=maxscale'+'\n'+'baseurl='+repo['repo']+'\n'+'gpgkey='+repo['repo_key']+'\n'+ 'gpgcheck=1'
      slesrepofile.close
    else
      $out.info 'Unknown mdbci platform!'
      return 1
    end

  end

  # TODO
  '''
    /home/h05t/.rbenv/versions/2.2.2/lib/ruby/gems/2.2.0/gems/net-scp-1.2.1/lib/net/scp.rb:365:in
    block (3 levels) in start_command: SCP did not finish successfully (1):  (Net::SCP::Error)
  '''
  # for net-scp version
  def self.maxscaleMdbciNetScpCmd(dir, platform, repo, mdbci_params)

    if platform == 'ubuntu' || platform == 'debian'
      debrepofile = File.open(dir+'/maxscale.list', 'w')
      debrepofile.puts 'deb '+repo['repo']
      debrepofile.close
      #
      keyfile = IO.read(dir.to_s+'/KEYS/'+mdbci_params['keyfile'].to_s)
      Net::SSH.start(mdbci_params['IP'].to_s, mdbci_params['user'].to_s, :key_data => keyfile.to_s, :keys_only => true) do |ssh|
        channel = ssh.scp.upload!(dir+'/maxscale.list', '/etc/apt/sources.list.d')
        channel.wait
        #$out.info result.to_s
      end
      #
    elsif platform == 'rhel' || platform == 'centos' || platform == 'fedora'
      rhelrepofile = File.open(dir+'/maxscale.repo', 'w')
      rhelrepofile.puts '[maxscale]'+'\n'+'name=maxscale'+'\n'+'baseurl='+repo['repo']+'\n'+'gpgkey='+repo['repo_key']+'\n'+ 'gpgcheck=1'
      rhelrepofile.close
      #
      Net.SCP.upload!(mdbci_params['IP'].to_s, mdbci_params['user'].to_s, dir+'/maxscale.list', '/etc/yum.repos.d/', 'key')
      #
    elsif platform == 'sles' || platform == 'suse' || platform == 'opensuse'
      slesrepofile = File.open(dir+'/maxscale.repo', 'w')
      slesrepofile.puts = '[maxscale]'+'\n'+'name=maxscale'+'\n'+'baseurl='+repo['repo']+'\n'+'gpgkey='+repo['repo_key']+'\n'+ 'gpgcheck=1'
      slesrepofile.close
      #
      Net.SCP.upload!(mdbci_params['IP'].to_s, mdbci_params['user'].to_s, dir+'/maxscale.list', '/etc/zypp/repos.d/', 'key')
      #
    else
      $out.info 'Unknown mdbci platform!'
      return 1
    end

  end

end

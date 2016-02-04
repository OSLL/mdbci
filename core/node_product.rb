require 'scanf'
require 'yaml'
require 'shellwords'

require_relative  '../core/out'


class NodeProduct
  #
  #
  def NodeProduct.getProductRepoParameters(product, box)

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
  # Get product repo params from repo manager (repo.d/)
  # platform format = platform_name^platform_version
  def NodeProduct.getProductRepo(product_name, product_version, platform)
    repokey = product_name+'@'+product_version+'+'+ platform
    repo = $session.repos.getRepo(repokey)
    $out.info 'Repo key is '+repokey + ' ... ' + (repo.nil? ? 'NOT_FOUND' : 'FOUND')

    if repo.nil?; return nil; end

    return repo
  end
  #
  #
  # Setup repo for product to nodes (install product repo and update it)
  # Supported products: Maxscale
  #
  # P.S. Require to add NOPASSWD:ALL to /etc/sudoers for a mdbci node user!
  # for example, vagranttest ALL=(ALL) NOPASSWD:ALL
  #
  def self.setupProductRepo(args)

    pwd = Dir.pwd

    if args.nil?
      $out.error 'Configuration name is required'
      return 1
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
            full_platform = $session.platformKey(box)
            #$out.info 'Install '+$session.nodeProduct.to_s+' repo to '+platform.to_s
            if $session.nodeProduct == 'maxscale'
              repo = getProductRepo('maxscale', 'default', full_platform)
              if !repo.nil?
                # # { ssh ... } version
                command = setupProductRepoToMdbciCmd(platform[0], repo)
                p command.to_s
                #cmd = 'ssh -i ' + pwd.to_s+'/KEYS/'+mdbci_params['keyfile'].to_s + ' '\
                #              + mdbci_params['user'].to_s + '@'\
                #              + mdbci_params['IP'].to_s + ' '\
                #              + "'" + command.to_s + "'"
                #$out.info 'Running ['+cmd+'] on '+args[0].to_s+'/'+args[1].to_s
                #vagrant_out = `#{cmd}`
                #$out.out vagrant_out
              else
                $out.error 'No such product for this node!'
                return 1
              end
            else
              repo = getProductRepo($session.nodeProduct, $session.productVersion, full_platform)
              if !repo.nil?
                p repo['repo'].to_s + ", " + repo['repo_key']
              else
                $out.error 'No such product for this node!'
                return 1
              end
            end
          end
        end
      else
        mdbci_node = $session.mdbciNodes.find { |elem| elem[0].to_s == args[1] }
        box = mdbci_node[1]['box'].to_s
        if !box.empty?
          mdbci_params = $session.boxes.getBox(box)
          full_platform = $session.platformKey(box)
          #$out.info 'Install '+$session.nodeProduct.to_s+' repo to '+platform.to_s
          if $session.nodeProduct == 'maxscale'
            repo = getProductRepo('maxscale', 'default', full_platform)
            if !repo.nil?
              command = setupProductRepoToMdbciCmd(platform[0], repo)
              p command.to_s
              #cmd = 'ssh -i ' + pwd.to_s+'/KEYS/'+mdbci_params['keyfile'].to_s + ' '\
              #                + mdbci_params['user'].to_s + '@'\
              #                + mdbci_params['IP'].to_s + ' '\
              #                + "'" + command + "'"
              #$out.info 'Running ['+cmd+'] on '+args[0].to_s+'/'+args[1].to_s
              #vagrant_out = `#{cmd}`
              #$out.out vagrant_out
            else
              $out.error 'No such product for this node!'
              return 1
            end
          else
            repo = getProductRepo($session.nodeProduct, $session.productVersion, full_platform)
            if !repo.nil?
              p repo['repo'].to_s + ", " + repo['repo_key']
            else
              $out.error 'No such product for this node!'
              return 1
            end
          end
        end
      end
    else # aws, vbox, libvirt, docker nodes
      Dir.chdir args[0]
      $session.loadTemplateNodes
      if args[1].nil? # No node argument, copy keys to all nodes
        $session.templateNodes.each do |node|
          full_platform = $session.loadNodePlatform(node[0].to_s)
          #$out.info 'Install '+$session.nodeProduct.to_s+' repo to '+platform.to_s
          if $session.nodeProduct == 'maxscale'
            repo = getProductRepo('maxscale', 'default', full_platform)
            if !repo.nil?
              cmd = setupProductRepoCmd(full_platform, node[0], repo)
              p cmd.to_s
              #vagrant_out = `#{cmd}`
              #$out.out vagrant_out
            else
              $out.error 'No such product for this node!'
              return 1
            end
          else
            repo = getProductRepo($session.nodeProduct, $session.productVersion, full_platform)
            if !repo.nil?
              p repo['repo'].to_s + ", " + repo['repo_key']
            else
              $out.error 'No such product for this node!'
              return 1
            end
          end
        end
      else
        node = $session.templateNodes.find { |elem| elem[0].to_s == args[1] }
        full_platform = $session.loadNodePlatform(node[0].to_s)
        #$out.info 'Install '+$session.nodeProduct.to_s+' repo to '+platform.to_s
        if $session.nodeProduct == 'maxscale'
          repo = getProductRepo('maxscale', 'default', full_platform)
          if !repo.nil?
            cmd = setupProductRepoCmd(platform, node[0], repo)
            p cmd.to_s
            #vagrant_out = `#{cmd}`
            #$out.out vagrant_out
          else
            $out.error 'No such product for this node!'
            return 1
          end
        else
          repo = getProductRepo($session.nodeProduct, $session.productVersion, full_platform)
          if !repo.nil?
            p repo['repo'].to_s + ", " + repo['repo_key']
          else
            $out.error 'No such product for this node!'
            return 1
          end
        end
      end
    end

    Dir.chdir pwd
    return 0
  end

  def NodeProduct.setupProductRepoCmd(full_platform, node_name, repo)
    platform = full_platform.split('^')
    if platform[0] == 'ubuntu' || platform[0] == 'debian'
      cmd_install_repo = 'vagrant ssh '+node_name+' -c "sudo apt-key adv --recv-keys --keyserver keyserver.ubuntu.com '+repo['repo_key'].to_s+' && '\
                       + 'sudo dd if=/dev/null of=/etc/apt/sources.list.d/'+$session.nodeProduct.to_s+'.list && '\
		                   + 'sudo echo -e \'deb '+repo['repo'].to_s+'\' | sudo tee -a /etc/apt/sources.list.d/'+$session.nodeProduct.to_s+'.list && '\
		                   + 'sudo apt-get update"'
    elsif platform[0] == 'rhel' || platform[0] == 'centos' || platform[0] == 'fedora'
      cmd_install_repo = 'vagrant ssh '+node_name+' -c "sudo dd if=/dev/null of=/etc/yum.repos.d/'+$session.nodeProduct.to_s+'.repo && '\
		                   + 'sudo echo -e \'['+$session.nodeProduct.to_s+']'+'\n'+'name='+$session.nodeProduct.to_s+'\n'+'baseurl='+Shellwords.escape(repo['repo'].to_s)+'\n'\
		                   + 'gpgkey='+Shellwords.escape(repo['repo_key'].to_s)+'\n'\
		                   + 'gpgcheck=1\' | sudo tee -a /etc/yum.repos.d/'+$session.nodeProduct.to_s+'.repo && '\
		                   + 'sudo yum clean all && sudo yum update '+$session.nodeProduct.to_s+'"'
    elsif platform[0] == 'sles' || platform[0] == 'suse' || platform[0] == 'opensuse'
      cmd_install_repo = 'vagrant ssh '+node_name+' -c "sudo dd if=/dev/null of=/etc/zypp/repos.d/'+$session.nodeProduct.to_s+'.repo && '\
		                   + 'sudo echo -e \'['+$session.nodeProduct.to_s+']'+'\n'+'name='+$session.nodeProduct.to_s+'\n'+'baseurl='+Shellwords.escape(repo['repo'].to_s)+'\n'\
		                   + 'gpgkey='+Shellwords.escape(repo['repo_key'].to_s)+'\n'\
		                   + 'gpgcheck=1\' | sudo tee -a /etc/zypp/repos.d/'+$session.nodeProduct.to_s+'.repo && '\
		                   + 'sudo zypper up '+$session.nodeProduct.to_s+'"'
    end
    return cmd_install_repo
  end

  # for #{ ssh ... } version
  def NodeProduct.setupProductRepoToMdbciCmd(full_platform, repo)
    platform = full_platform.split('^')
    if platform[0] == 'ubuntu' || platform[0] == 'debian'
      cmd_install_repo = 'sudo apt-key adv --recv-keys --keyserver keyserver.ubuntu.com '+repo['repo_key'].to_s+' && '\
                       + 'sudo dd if=/dev/null of=/etc/apt/sources.list.d/'+$session.nodeProduct.to_s+'.list && '\
		                   + 'sudo echo -e \'deb '+repo['repo'].to_s+'\' | sudo tee -a /etc/apt/sources.list.d/'+$session.nodeProduct.to_s+'.list && '\
		                   + 'sudo apt-get update'
    elsif platform[0] == 'rhel' || platform[0] == 'centos' || platform[0] == 'fedora'
      cmd_install_repo = 'sudo dd if=/dev/null of=/etc/yum.repos.d/'+$session.nodeProduct.to_s+'.repo && '\
		                   + 'sudo echo -e \'['+$session.nodeProduct.to_s+']'+'\n'+'name='+$session.nodeProduct.to_s+'\n'+'baseurl='+Shellwords.escape(repo['repo'].to_s)+'\n'\
		                   + 'gpgkey='+Shellwords.escape(repo['repo_key'].to_s)+'\n'\
                       + 'gpgcheck=1\' | sudo tee -a /etc/yum.repos.d/'+$session.nodeProduct.to_s+'.repo && '\
		                   + 'sudo yum clean all && sudo yum update '+$session.nodeProduct.to_s+''
    elsif platform[0] == 'sles' || platform[0] == 'suse' || platform[0] == 'opensuse'
      cmd_install_repo = 'sudo dd if=/dev/null of=/etc/zypp/repos.d/'+$session.nodeProduct.to_s+'.repo && '\
		                   + 'sudo echo -e \'['+$session.nodeProduct.to_s+']'+'\n'+'name='+$session.nodeProduct.to_s+'\n'+'baseurl='+Shellwords.escape(repo['repo'].to_s)+'\n'\
		                   + 'gpgkey='+Shellwords.escape(repo['repo_key'].to_s)+'\n'\
                       + 'gpgcheck=1\' | sudo tee -a /etc/zypp/repos.d/'+$session.nodeProduct.to_s+'.repo && '\
		                   + 'sudo zypper up '+$session.nodeProduct.to_s
    end
    return cmd_install_repo
  end

end

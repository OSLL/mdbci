require 'scanf'
require 'yaml'
require 'shellwords'
require 'json'

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

    exit_code = 1
    possibly_failed_command = ''

    pwd = Dir.pwd

    if args.nil?
      $out.error 'Configuration name is required'
      exit_code = 1
    end

    args = args.split('/')

    # mdbci box
    if File.exist?(args[0]+'/mdbci_template')
      $session.loadMdbciNodes args[0]
      if args[1].nil?     # read ip for all nodes
        if $session.mdbciNodes.length == 0
          $out.error "0 nodes found in #{args[0]}"
          exit_code = 1
        end
        $session.mdbciNodes.each do |node|
          if $session.mdbciNodes.length == 0
            $out.error "0 nodes found in #{args[0]}"
            exit_code = 1
          end
          box = node[1]['box'].to_s
          if !box.empty?
            mdbci_params = $session.boxes.getBox(box)
            if mdbci_params == nil
              $out.error "box #{box} not found"
              exit_code = 1
            end
            full_platform = $session.platformKey(box)
            if full_platform == "UNKNOWN"
              $out.error "platform for box #{box} not found"
              exit_code = 1
            end
            # get product repo
            if $session.nodeProduct == 'maxscale'
              repo = getProductRepo('maxscale', 'default', full_platform)
            else
              repo = getProductRepo($session.nodeProduct, $session.productVersion, full_platform)
            end
            # execute command
            if !repo.nil?
              command = setupProductRepoToMdbciCmd(full_platform, repo)
              cmd = 'ssh -i ' + pwd.to_s+'/KEYS/'+mdbci_params['keyfile'].to_s + ' '\
                              + mdbci_params['user'].to_s + '@'\
                              + mdbci_params['IP'].to_s + ' '\
                              + "'" + command.to_s + "'"
              $out.info 'Running ['+cmd+'] on '+args[0].to_s+'/'+args[1].to_s
              vagrant_out = `#{cmd}`
              $out.info vagrant_out

              exit_code = $?.exitstatus
              possibly_failed_command = cmd
            else
              $out.error 'No such product for this node!'
              exit_code = 1
            end
          end
        end
      else
        mdbci_node = $session.mdbciNodes.find { |elem| elem[0].to_s == args[1] }
        if mdbci_node == nil
          $out.error "node #{args[1]} not found in #{args[0]}"
          exit_code = 1
        end
        box = mdbci_node[1]['box'].to_s
        if !box.empty?
          mdbci_params = $session.boxes.getBox(box)
          if mdbci_params == nil
            $out.error "box #{box} not found"
            exit_code = 1
          end
          full_platform = $session.platformKey(box)
          if full_platform == "UNKNOWN"
            $out.error "platform for box #{box} not found"
            exit_code = 1
          end
          # get product repo
          if $session.nodeProduct == 'maxscale'
            repo = getProductRepo('maxscale', 'default', full_platform)
          else
            repo = getProductRepo($session.nodeProduct, $session.productVersion, full_platform)
          end
          # execute command
          if !repo.nil?
            command = setupProductRepoToMdbciCmd(full_platform, repo)
            cmd = 'ssh -i ' + pwd.to_s+'/KEYS/'+mdbci_params['keyfile'].to_s + ' '\
                            + mdbci_params['user'].to_s + '@'\
                            + mdbci_params['IP'].to_s + ' '\
                            + "'" + command.to_s + "'"
            $out.info 'Running ['+cmd+'] on '+args[0].to_s+'/'+args[1].to_s
            vagrant_out = `#{cmd}`
            $out.info vagrant_out

            exit_code = $?.exitstatus
            possibly_failed_command = cmd
          else
            $out.error 'No such product for this node!'
            exit_code = 1
          end
        else
          $out.error "box parameter not found in defenition of node #{args[0]}/#{args[1]}"
          exit_code = 1
        end
      end
    else # aws, vbox, libvirt, docker nodes
      Dir.chdir args[0]
      $session.loadTemplateNodes
      if args[1].nil? # No node argument, copy keys to all nodes
        if $session.templateNodes.length == 0
          $out.error "0 nodes found in #{args[0]}"
          exit_code = 1
        end
        $session.templateNodes.each do |node|
          full_platform = $session.loadNodePlatform(node[0].to_s)
          if full_platform == nil
            $out.error "platform for node #{node[0]} not found"
            exit_code = 1
          end
          # get product repo
          if $session.nodeProduct == 'maxscale'
            repo = getProductRepo('maxscale', 'default', full_platform)
          else
            repo = getProductRepo($session.nodeProduct, $session.productVersion, full_platform)
          end
          # execute command
          if !repo.nil?
            cmd = setupProductRepoCmd(full_platform, node[0], repo)
            vagrant_out = `#{cmd}`
            $out.info vagrant_out
            
            exit_code = $?.exitstatus
            possibly_failed_command = cmd
          else
            $out.error 'No such product for this node!'
            exit_code = 1
          end
        end
      else
        node = $session.templateNodes.find { |elem| elem[0].to_s == args[1] }
        if node == nil
          $out.error "node #{args[1]} not found in #{args[0]}"
          exit_code = 1
        end
        full_platform = $session.loadNodePlatform(node[0].to_s)
        if full_platform == nil
          $out.error "platform for node #{args[1]} not found"
          exit_code = 1
        end
        # get product repo
        if $session.nodeProduct == 'maxscale'
          repo = getProductRepo('maxscale', 'default', full_platform)
        else
          repo = getProductRepo($session.nodeProduct, $session.productVersion, full_platform)
        end
        # execute command
        if !repo.nil?
          cmd = setupProductRepoCmd(full_platform, node[0], repo)
          vagrant_out = `#{cmd}`
          $out.info vagrant_out

          exit_code = $?.exitstatus
          possibly_failed_command = cmd
        else
          $out.error 'No such product for this node!'
          exit_code = 1
        end
      end
    end

    Dir.chdir pwd

    if exit_code != 0
      $out.error "command #{possibly_failed_command} exit with non-zero exit code: #{exit_code}"
      exit_code = 1
    end

    return exit_code
  end
  #
  #
  def NodeProduct.setupProductRepoCmd(full_platform, node_name, repo)
    platform = full_platform.split('^')
    $out.info 'Setup '+$session.nodeProduct.to_s+' repo on '+platform[0].to_s
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
		                   + 'sudo zypper --no-gpg-check ref '+$session.nodeProduct.to_s+'"'
    end
    return cmd_install_repo
  end

  # for #{ ssh ... } version
  def NodeProduct.setupProductRepoToMdbciCmd(full_platform, repo)
    platform = full_platform.split('^')
    $out.info 'Setup '+$session.nodeProduct.to_s+' repo on '+platform[0].to_s
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
		                   + 'sudo zypper --no-gpg-check ref '+$session.nodeProduct.to_s
    end
    return cmd_install_repo
  end
  #
  #
  # Install product command. Supported: MySQL, MariaDB, MariaDB-Galera, Maxscale

  # Returns packages to install or nil
  def NodeProduct.validateProduct(platform, products)
    products.keys.any? do |k|

      if platform.include? k
        # If platform exists in products list
        if products[k].has_key? $session.nodeProduct
          # If current platform have product
          if products[k][$session.nodeProduct].class == Hash
            # If product have concrete versions
            if $session.productVersion != nil
              # If version specified during execution
              if products[k][$session.nodeProduct].has_key? $session.productVersion
                # If defined version exists
                return products[k][$session.nodeProduct][$session.productVersion]
              end
            end
          else
            # If product without versions
            return products[k][$session.nodeProduct]
          end
        end
      end
    end
    # Wrong platform/product/version
    return nil
  end

  def self.installProduct(args)

    exit_code = 1
    possibly_failed_command = ''

    pwd = Dir.pwd

    # Loading file with product packages to every system
    products = JSON.parse(File.read('products.json'))

    if args.nil?
      $out.error 'Configuration name is required'
      exit_code = 1
    end

    args = args.split('/')
    # mdbci box
    if File.exist?(args[0]+'/mdbci_template')
      $session.loadMdbciNodes args[0]
      if args[1].nil?     # read ip for all nodes
        if $session.mdbciNodes.length == 0
          $our.error "nodes not found in #{args[0]}"
          exit_code = 1
        end

        $session.mdbciNodes.each do |node|
          box = node[1]['box'].to_s
          if !box.empty?
            mdbci_params = $session.boxes.getBox(box)
            platform = $session.boxes.platformKey(box).split('^')

            packages = validateProduct(platform[0], products)
            if packages == nil
              version = $session.productVersion != nil ? ' with version ' + $session.productVersion : '(maybe you need to specify version)'
              $out.error "product #{$session.nodeProduct} #{version} not found for platform #{platform[0]}"
              exit_code = 1
            end

            $out.info 'Install '+$session.nodeProduct.to_s+' repo to '+platform[0]

            # execute command
            command = installProductToMdbciCmd(platform[0], packages)
            cmd = 'ssh -i ' + pwd.to_s+'/KEYS/'+mdbci_params['keyfile'].to_s + ' '\
                            + mdbci_params['user'].to_s + '@'\
                            + mdbci_params['IP'].to_s + ' '\
                            + "'" + command.to_s + "'"
            $out.info 'Running ['+cmd+'] on '+args[0].to_s+'/'+args[1].to_s
            vagrant_out = `#{cmd}`
            #$out.out vagrant_out

            exit_code = $?.exitstatus
            possibly_failed_command = cmd
          end
        end
      else
        mdbci_node = $session.mdbciNodes.find { |elem| elem[0].to_s == args[1] }

        if mdbci_node == nil
          $out.error "node #{args[1]} not found in #{args[0]}"
          exit_code = 1
        end

        box = mdbci_node[1]['box'].to_s
        if !box.empty?
          mdbci_params = $session.boxes.getBox(box)
          platform = $session.boxes.platformKey(box).split('^')

          packages = validateProduct(platform[0], products)
          if packages == nil
            version = $session.productVersion != nil ? ' with version ' + $session.productVersion : '(maybe you need to specify version)'
            $out.error "product #{$session.nodeProduct} #{version} not found for platform #{platform[0]}"
            exit_code = 1
          end

          $out.info 'Install '+$session.nodeProduct.to_s+' product to '+platform[0].to_s

          # execute command
          command = installProductToMdbciCmd(platform[0], packages)
          cmd = 'ssh -i ' + pwd.to_s+'/KEYS/'+mdbci_params['keyfile'].to_s + ' '\
                            + mdbci_params['user'].to_s + '@'\
                            + mdbci_params['IP'].to_s + ' '\
                            + "'" + command.to_s + "'"
          $out.info 'Running ['+cmd+'] on '+args[0].to_s+'/'+args[1].to_s
          vagrant_out = `#{cmd}`
          #$out.out vagrant_out

          exit_code = $?.exitstatus
          possibly_failed_command = cmd
        end
      end
    else # aws, vbox, libvirt, docker nodes
      Dir.chdir args[0]
      $session.loadTemplateNodes

      if args[1].nil? # No node argument, copy keys to all nodes

        if $session.templateNodes.length == 0
          $our.error "nodes not  found in #{args[0]}"
          exit_code = 1
        end

        $session.templateNodes.each do |node|
          platform = $session.loadNodePlatform(node[0].to_s).split('^')

          packages = validateProduct(platform[0], products)
          if packages == nil
            version = $session.productVersion != nil ? ' with version ' + $session.productVersion : '(maybe you need to specify version)'
            $out.error "product #{$session.nodeProduct} #{version} not found for platform #{platform[0]}"
            exit_code = 1
          end

          $out.info 'Install '+$session.nodeProduct.to_s+' product to '+platform[0]

          # execute command
          cmd = installProductCmd(platform[0], node[0], packages)
          vagrant_out = `#{cmd}`
          #$out.info vagrant_out

          exit_code = $?.exitstatus
          possibly_failed_command = cmd
        end
      else
        node = $session.templateNodes.find { |elem| elem[0].to_s == args[1] }

        if node == nil
          $out.error "node #{args[1]} not found in #{args[0]}"
          exit_code = 1
        end

        platform = $session.loadNodePlatform(node[0].to_s).split('^')

        packages = validateProduct(platform[0], products)
        if packages == nil
          $out.error "product #{$session.nodeProduct} not found for platform #{platform[0]}"
          exit_code = 1
        end

        $out.info 'Install '+$session.nodeProduct.to_s+' product to '+platform.to_s
        # execute command
        cmd = installProductCmd(platform[0], node[0], packages)
        vagrant_out = `#{cmd}`

        exit_code = $?.exitstatus
        possibly_failed_command = cmd
      end
    end

    Dir.chdir pwd

    if exit_code != 0
      $out.error "command #{possibly_failed_command} exit with non-zero code: #{exit_code}"
      exit_code = 1
    end

    return exit_code
  end

  # install Maxscale product command for Vagrant nodes
  def NodeProduct.installProductCmd(platform, node_name, packages)
    if platform == 'ubuntu' || platform == 'debian'
      cmd_install_product = 'vagrant ssh '+node_name+' -c "sudo DEBIAN_FRONTEND=noninteractive apt-get -y install '+ packages +'"'
    elsif platform == 'rhel' || platform == 'centos' || platform == 'fedora'
      cmd_install_product = 'vagrant ssh '+node_name+' -c "sudo yum -y install '+ packages + '"'
    elsif platform == 'sles' || platform == 'suse' || platform == 'opensuse'
      packages_with_repository = ''
      packages.split(' ').each { |package| packages_with_repository += $session.nodeProduct + ":" + package + ' ' }
      cmd_install_product = 'vagrant ssh '+node_name+' -c "sudo zypper --non-interactive remove MariaDB*; sudo zypper --non-interactive install -f '+ packages_with_repository +'"'
    end
    return cmd_install_product
  end
  #
  # #{ ssh ... } version of install Maxscale product on a mdbci nodes
  def NodeProduct.installProductToMdbciCmd(platform, packages)
    if platform == 'ubuntu' || platform == 'debian'
      cmd_install_product = 'sudo DEBIAN_FRONTEND=noninteractive apt-get -y install '+ packages
    elsif platform == 'rhel' || platform == 'centos' || platform == 'fedora'
      cmd_install_product = 'sudo yum -y install '+ packages
    elsif platform == 'sles' || platform == 'suse' || platform == 'opensuse'
      packages_with_repository = ''
      packages.split(' ').each { |package| packages_with_repository += $session.nodeProduct + ":" + package + ' ' }
      cmd_install_product = 'sudo zypper --non-interactive remove MariaDB*; sudo zypper --non-interactive install -f '+ packages_with_repository
    end
    return cmd_install_product
  end

end

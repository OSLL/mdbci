require 'scanf'
require 'yaml'
require 'shellwords'
require_relative 'out'


class NodeProduct
  #
  #
  CLEAN_ALL = "sudo yum clean all"

  def self.get_product_repo_parameters(product, box)
    repo = nil

    if !product['repo'].nil?
      repo_name = product['repo']
      unless $session.repos.knownRepo?(repo_name)
        $out.warning 'Unknown key for repo '+repo_name.to_s+' will be skipped'
        return "#NONE, due invalid repo name \n"
      end
      repo = $session.repos.getRepo(repo_name)
      product_name = $session.repos.productName(repo_name)
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
  def self.get_product_repo(product_name, product_version, platform)
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
  def self.setup_product_repo(args)
    pwd = Dir.pwd
    raise 'Configuration name is required' if args.nil?
    args = args.split('/')
    # mdbci box
    if File.exist?(args[0]+'/mdbci_template')
      $session.loadMdbciNodes args[0]
      if args[1].nil?     # read ip for all nodes
        if $session.mdbciNodes.length == 0
          raise "0 nodes found in #{args[0]}"
        end
        $session.mdbciNodes.each do |node|
          box = node[1]['box'].to_s
          raise "Box parameter is not found in #{node[0]}"if box.empty?
          mdbci_params = $session.boxes.getBox(box)
          raise "Box #{box} is not found" if mdbci_params.nil?
          full_platform = $session.platformKey(box)
          raise "Platform for box #{box} is not found" if full_platform == "UNKNOWN"
          # get product repo
          if $session.nodeProduct == 'maxscale'
            repo = get_product_repo('maxscale', 'default', full_platform)
          else
            repo = get_product_repo($session.nodeProduct, $session.productVersion, full_platform)
          end
          # execute command
          raise 'No such product for this node!' if repo.nil?
          command = setup_product_repo_to_mdbci_cmd(full_platform, repo)
          cmd = "ssh -i #{$mdbci_exec_dir}/KEYS/#{mdbci_params['keyfile']} #{mdbci_params['user']}@#{mdbci_params['IP']} '#{command}'"
          $out.info "Running #{cmd} on #{args[0]}/#{args[1]}"
          vagrant_out = `#{cmd}`
          $out.info vagrant_out
          raise "command #{cmd} exit with non-zero exit code: #{$?.exitstatus}" if $?.exitstatus != 0
        end
      else
        mdbci_node = $session.mdbciNodes.find { |elem| elem[0].to_s == args[1] }
        raise "Node #{args[1]} is not found in #{args[0]}" if mdbci_node.nil?
        box = mdbci_node[1]['box'].to_s
        raise "Box parameter is not found in defenition of node #{args[0]}/#{args[1]}" if box.empty?
        mdbci_params = $session.boxes.getBox(box)
        raise "Box #{box} is not found" if mdbci_params.nil?
        full_platform = $session.platformKey(box)
        raise  "Platform for box #{box} not found" if full_platform == "UNKNOWN"
        # get product repo
        if $session.nodeProduct == 'maxscale'
          repo = get_product_repo('maxscale', 'default', full_platform)
        else
          repo = get_product_repo($session.nodeProduct, $session.productVersion, full_platform)
        end
        # execute command
        raise 'No such product for this node!' if repo.nil?
        command = setup_product_repo_to_mdbci_cmd(full_platform, repo)
        cmd = "ssh -i #{$mdbci_exec_dir}/KEYS/#{mdbci_params['keyfile']} #{mdbci_params['user']}@#{mdbci_params['IP']} '#{command}'"
        $out.info 'Running ['+cmd+'] on '+args[0].to_s+'/'+args[1].to_s
        vagrant_out = `#{cmd}`
        $out.info vagrant_out
        raise "command #{cmd} exit with non-zero exit code: #{$?.exitstatus}" if $?.exitstatus != 0
      end
    else # aws, vbox, libvirt, docker nodes
      Dir.chdir $work_dir+'/'+args[0]
      $session.loadTemplateNodes
      if args[1].nil? # No node argument, copy keys to all nodes
        raise "0 nodes found in #{args[0]}" if $session.templateNodes.empty?
        $session.templateNodes.each do |node|
          full_platform = $session.loadNodePlatform(node[0].to_s)
          raise "platform for node #{node[0]} not found" if full_platform.nil?
          # get product repo
          if $session.nodeProduct == 'maxscale'
            repo = get_product_repo('maxscale', 'default', full_platform)
          else
            repo = get_product_repo($session.nodeProduct, $session.productVersion, full_platform)
          end
          # execute command
          raise 'No such product for this node!' if repo.nil?
          cmd = setup_product_repo_cmd(full_platform, node[0], repo)
          vagrant_out = `#{cmd}`
          $out.info vagrant_out
          raise "command #{cmd} exit with non-zero exit code: #{$?.exitstatus}" if $?.exitstatus != 0
        end
      else
        node = $session.templateNodes.find { |elem| elem[0].to_s == args[1] }
        raise "node #{args[1]} not found in #{args[0]}" if node == nil
        full_platform = $session.loadNodePlatform(node[0].to_s)
        raise "Platform for node #{args[1]} not found" if full_platform.nil?
        # get product repo
        if $session.nodeProduct == 'maxscale'
          repo = get_product_repo('maxscale', 'default', full_platform)
        else
          repo = get_product_repo($session.nodeProduct, $session.productVersion, full_platform)
        end
        # execute command
        raise 'No such product for this node!' if repo.nil?
        cmd = setup_product_repo_cmd(full_platform, node[0], repo)
        vagrant_out = `#{cmd}`
        $out.info vagrant_out
        raise "command #{cmd} exit with non-zero exit code: #{$?.exitstatus}" if $?.exitstatus != 0
      end
    end
    Dir.chdir pwd
    0
  end
  #
  #

  def self.suse_setup_product_repo_cmd(repo)
    repo_path = "/etc/zypp/repos.d/#{$session.nodeProduct.to_s}.repo"
    setup_suse_repo = "sudo dd if=/dev/null of=#{repo_path} && " +
        "sudo echo -e \"[#{Shellwords.escape($session.nodeProduct)}]\\n\" | sudo tee -a #{repo_path} && " +
        "sudo echo -e name = \"#{Shellwords.escape($session.nodeProduct)}\\n\" | sudo tee -a #{repo_path} && " +
        "sudo echo -e baseurl = \"#{Shellwords.escape(repo['repo'].to_s)}\\n\" | sudo tee -a #{repo_path} && " +
        "sudo echo -e gpgkey=\"#{Shellwords.escape(repo['repo_key'].to_s)}\\ngpgcheck=1\" | sudo tee -a #{repo_path}"
    return "#{setup_suse_repo}  && " +
        "sudo zypper --no-gpg-check ref #{$session.nodeProduct.to_s} && " +
        "sudo rm /etc/zypp/repos.d/#{$session.nodeProduct.to_s}.repo && " +
        "#{setup_suse_repo}"
  end

  def self.setup_product_repo_cmd(full_platform, node_name, repo)
    platform = full_platform.split('^')
    $out.info 'Setup '+$session.nodeProduct.to_s+' repo on '+platform[0].to_s
    if platform[0] == 'ubuntu' || platform[0] == 'debian'
      cmd_install_repo = 'vagrant ssh '+node_name+' -c "sudo apt-get install -y --force-yes dirmngr &&'\
                       + 'sudo apt-key adv --recv-keys --keyserver keyserver.ubuntu.com '+repo['repo_key'].to_s+' && '\
                       + 'sudo dd if=/dev/null of=/etc/apt/sources.list.d/'+$session.nodeProduct.to_s+'.list && '\
                       + 'sudo echo -e \'deb '+repo['repo'].to_s+'\' | sudo tee -a /etc/apt/sources.list.d/'+$session.nodeProduct.to_s+'.list && '\
                       + 'sudo apt-get update"'
    elsif platform[0] == 'rhel' || platform[0] == 'centos' || platform[0] == 'fedora'
      cmd_install_repo = 'vagrant ssh '+node_name+' -c "sudo dd if=/dev/null of=/etc/yum.repos.d/'+$session.nodeProduct.to_s+'.repo && '\
                       + 'sudo echo -e \'['+$session.nodeProduct.to_s+']'+'\n'+'name='+$session.nodeProduct.to_s+'\n'+'baseurl='+Shellwords.escape(repo['repo'].to_s)+'\n'\
                       + 'gpgkey='+Shellwords.escape(repo['repo_key'].to_s)+'\n'\
                       + 'gpgcheck=1\' | sudo tee -a /etc/yum.repos.d/'+$session.nodeProduct.to_s+'.repo && '\
                       + CLEAN_ALL+' && sudo yum -y update '+$session.nodeProduct.to_s+'"'
    elsif platform[0] == 'sles' || platform[0] == 'suse' || platform[0] == 'opensuse'
      cmd_install_repo = "vagrant ssh #{node_name} -c '#{suse_setup_product_repo_cmd(repo)}'"
    end
    cmd_install_repo
  end

  # for #{ ssh ... } version
  def self.setup_product_repo_to_mdbci_cmd(full_platform, repo)
    platform = full_platform.split('^')
    $out.info 'Setup '+$session.nodeProduct.to_s+' repo on '+platform[0].to_s
    if platform[0] == 'ubuntu' || platform[0] == 'debian'
      cmd_install_repo = 'sudo apt-get install -y --force-yes dirmngr && '\
                       + 'sudo apt-key adv --recv-keys --keyserver keyserver.ubuntu.com '+repo['repo_key'].to_s+' && '\
                       + 'sudo dd if=/dev/null of=/etc/apt/sources.list.d/'+$session.nodeProduct.to_s+'.list && '\
                       + 'sudo echo -e \'deb '+repo['repo'].to_s+'\' | sudo tee -a /etc/apt/sources.list.d/'+$session.nodeProduct.to_s+'.list && '\
                       + 'sudo apt-get update'
    elsif platform[0] == 'rhel' || platform[0] == 'centos' || platform[0] == 'fedora'
      cmd_install_repo = 'sudo dd if=/dev/null of=/etc/yum.repos.d/'+$session.nodeProduct.to_s+'.repo && '\
                       + 'sudo echo -e \'['+$session.nodeProduct.to_s+']'+'\n'+'name='+$session.nodeProduct.to_s+'\n'+'baseurl='+Shellwords.escape(repo['repo'].to_s)+'\n'\
                       + 'gpgkey='+Shellwords.escape(repo['repo_key'].to_s)+'\n'\
                       + 'gpgcheck=1\' | sudo tee -a /etc/yum.repos.d/'+$session.nodeProduct.to_s+'.repo && '\
                       + CLEAN_ALL+' && sudo yum update '+$session.nodeProduct.to_s+''
    elsif platform[0] == 'sles' || platform[0] == 'suse' || platform[0] == 'opensuse'
      cmd_install_repo = suse_setup_product_repo_cmd(repo)
    end
    cmd_install_repo
  end
  #
  #
  # Install product command. Supported: MySQL, MariaDB, MariaDB-Galera, Maxscale

  # Searches the product configuration and returns the list of packages to install or nil
  # @param platform [String] name of the determined platform
  # @param products [Hash] product configuration table
  # @return [String] pagkages or nil if search did not succeed
  def self.validate_product(platform, products)
    product_to_install = $session.nodeProduct
    product_version = $session.productVersion

    return nil unless products.key?(platform)
    platform_config = products[platform]
    return nil unless platform_config.key?(product_to_install)
    product_config = platform_config[product_to_install]
    if product_config.kind_of?(Hash)
      return nill unless product_config.key?(product_version)
      return product_config[product_version]
    end
    product_config
  end

  def self.install_product(args)
    pwd = Dir.pwd
    # Loading file with product packages to every system
    products = YAML.load(File.read($session.find_configuration('products.yaml')))
    raise 'Configuration name is required' if args.nil?
    args = args.split('/')
    # mdbci box
    if File.exist?(args[0]+'/mdbci_template')
      $session.loadMdbciNodes args[0]
      if args[1].nil?     # read ip for all nodes
        $our.error "nodes not found in #{args[0]}" if $session.mdbciNodes.empty?
        $session.mdbciNodes.each do |node|
          box = node[1]['box'].to_s
          raise "Box parameter is not found for #{node[0]}" if box.empty?
          mdbci_params = $session.boxes.getBox(box)
          raise "Box is not found for #{node[0]}" if mdbci_params.nil?
          platform = $session.boxes.platformKey(box).split('^')
          packages = validate_product(platform[0], products)
          version = $session.productVersion != nil ? ' with version ' + $session.productVersion : '(maybe you need to specify version)'
          raise "Product #{$session.nodeProduct} #{version} not found for platform #{platform[0]}" if packages.nil?
          $out.info "Install #{$session.nodeProduct} repo to #{platform[0]}"
          # execute command
          command = install_product_to_mdbci_cmd(platform[0], packages)
          cmd = "ssh -i #{$mdbci_exec_dir}/KEYS/#{mdbci_params['keyfile']} #{mdbci_params['user']}@#{mdbci_params['IP']} '#{command}'"
          $out.info 'Running ['+cmd+'] on '+args[0].to_s+'/'+args[1].to_s
          vagrant_out = `#{cmd}`
          $out.info vagrant_out
          raise "command #{cmd} exit with non-zero code: #{$?.exitstatus}" if $?.exitstatus != 0
        end
      else
        mdbci_node = $session.mdbciNodes.find { |elem| elem[0].to_s == args[1] }
        raise "node #{args[1]} not found in #{args[0]}" if mdbci_node.nil?
        box = mdbci_node[1]['box'].to_s
        raise "Box parameter is not found for #{args[1]}/#{args[0]}" if box.empty?
        mdbci_params = $session.boxes.getBox(box)
        platform = $session.boxes.platformKey(box).split('^')
        packages = validate_product(platform[0], products)
        if packages == nil
          version = $session.productVersion != nil ? ' with version ' + $session.productVersion : '(maybe you need to specify version)'
          $out.error "product #{$session.nodeProduct} #{version} not found for platform #{platform[0]}"
          exit_code = 1
        end
        $out.info 'Install '+$session.nodeProduct.to_s+' product to '+platform[0].to_s
        # execute command
        command = install_product_to_mdbci_cmd(platform[0], packages)
        cmd = "ssh -i #{$mdbci_exec_dir}/KEYS/#{mdbci_params['keyfile']} #{mdbci_params['user']}@#{mdbci_params['IP']} '#{command}'"
        $out.info 'Running ['+cmd+'] on '+args[0].to_s+'/'+args[1].to_s
        vagrant_out = `#{cmd}`
        $out.info vagrant_out
        raise "command #{cmd} exit with non-zero code: #{$?.exitstatus}" if $?.exitstatus != 0
      end
    else # aws, vbox, libvirt, docker nodes
      Dir.chdir $work_dir+'/'+args[0]
      $session.loadTemplateNodes
      if args[1].nil? # No node argument, copy keys to all nodes
        raise "nodes not  found in #{args[0]}" if $session.templateNodes.empty?
        $session.templateNodes.each do |node|
          platform = $session.loadNodePlatform(node[0].to_s).split('^')
          packages = validate_product(platform[0], products)
          version = $session.productVersion != nil ? ' with version ' + $session.productVersion : '(maybe you need to specify version)'
          raise "product #{$session.nodeProduct} #{version} not found for platform #{platform[0]}" if packages.nil?
          $out.info 'Install '+$session.nodeProduct.to_s+' product to '+platform[0]
          # execute command
          cmd = install_product_cmd(platform[0], node[0], packages)
          vagrant_out = `#{cmd}`
          $out.info vagrant_out
          raise "command #{cmd} exit with non-zero code: #{$?.exitstatus}" if $?.exitstatus != 0
        end
      else
        node = $session.templateNodes.find { |elem| elem[0].to_s == args[1] }
        raise "node #{args[1]} not found in #{args[0]}" if node.nil?
        platform = $session.loadNodePlatform(node[0].to_s).split('^')
        packages = validate_product(platform[0], products)
        raise "product #{$session.nodeProduct} not found for platform #{platform[0]}" if packages.nil?
        $out.info 'Install '+$session.nodeProduct.to_s+' product to '+platform.to_s
        # execute command
        cmd = install_product_cmd(platform[0], node[0], packages)
        vagrant_out = `#{cmd}`
        $out.info vagrant_out
        raise "command #{cmd} exit with non-zero code: #{$?.exitstatus}" if $?.exitstatus != 0
      end
    end
    Dir.chdir pwd
    0
  end

  # install Maxscale product command for Vagrant nodes
  def self.install_product_cmd(platform, node_name, packages)
    if platform == 'ubuntu' || platform == 'debian'
      cmd_install_product = 'vagrant ssh '+node_name+' -c "sudo DEBIAN_FRONTEND=noninteractive apt-get -y install '+ packages +'"'
    elsif platform == 'rhel' || platform == 'centos' || platform == 'fedora'
      cmd_install_product = 'vagrant ssh '+node_name+' -c "'+ CLEAN_ALL + ' && sudo yum -y install '+ packages + '"'
    elsif platform == 'sles' || platform == 'suse' || platform == 'opensuse'
      packages_with_repository = ''
      packages.split(' ').each { |package| packages_with_repository += $session.nodeProduct + ":" + package + ' ' }
      cmd_install_product = 'vagrant ssh '+node_name+' -c "sudo zypper --non-interactive remove MariaDB*; sudo zypper --non-interactive install -f '+ packages_with_repository +'"'
    end
    cmd_install_product
  end

  #
  # #{ ssh ... } version of install Maxscale product on a mdbci nodes
  def self.install_product_to_mdbci_cmd(platform, packages)
    if platform == 'ubuntu' || platform == 'debian'
      cmd_install_product = 'sudo DEBIAN_FRONTEND=noninteractive apt-get -y install '+ packages
    elsif platform == 'rhel' || platform == 'centos' || platform == 'fedora'
      cmd_install_product = CLEAN_ALL + '&& sudo yum -y install '+ packages
    elsif platform == 'sles' || platform == 'suse' || platform == 'opensuse'
      packages_with_repository = ''
      packages.split(' ').each { |package| packages_with_repository += $session.nodeProduct + ":" + package + ' ' }
      cmd_install_product = 'sudo zypper --non-interactive remove MariaDB*; sudo zypper --non-interactive install -f '+ packages_with_repository
    end
    cmd_install_product
  end

end

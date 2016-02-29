require 'date'
require 'fileutils'

require_relative '../core/out'


class Generator

  def Generator.quote(string)
    return '"'+string+'"'
  end

  def Generator.vagrantFileHeader
    vagrantFileHeader = <<-EOF
# !! Generated content, do not edit !!
# Generated by MariaDB Continuous Integration Tool (http://github.com/OSLL/mdbci)

    EOF
    vagrantFileHeader += "\n####  Created "
    vagrantFileHeader += DateTime.now.to_s
    vagrantFileHeader += " ####\n\n"
  end

  def Generator.awsProviderConfigImport(aws_config_file)
    awsConfig = <<-EOF

### Import AWS Provider access config ###
require 'yaml'
    EOF
    awsConfig += 'aws_config = YAML.load_file(' + quote(aws_config_file.to_s) + ")['aws']\n"
    awsConfig += '## of import AWS Provider access config' + "\n"
    return awsConfig
  end

  def Generator.awsProviderConfig
    awsProviderConfig = <<-EOF

  ###           AWS Provider config block                 ###
  ###########################################################
  config.vm.box = "dummy"

  config.vm.provider :aws do |aws, override|
    aws.access_key_id = aws_config["access_key_id"]
    aws.secret_access_key = aws_config["secret_access_key"]
    aws.keypair_name = aws_config["keypair_name"]
    aws.region = aws_config["region"]
    aws.security_groups = aws_config["security_groups"]
    aws.user_data = aws_config["user_data"]
    override.ssh.private_key_path = aws_config["pemfile"]
    override.nfs.functional = false
  end ## of AWS Provider config block

    EOF
  end

  def Generator.providerConfig
    config = <<-EOF

### Default (VBox, Libvirt, Docker) Provider config ###
#######################################################
# Network autoconfiguration
config.vm.network "private_network", type: "dhcp"

config.vm.boot_timeout = 60
    EOF
  end

  def Generator.vagrantConfigHeader

    vagrantConfigHeader = <<-EOF

### Vagrant configuration block  ###
####################################
Vagrant.configure(2) do |config|
    EOF
  end

  def Generator.vagrantConfigFooter
    vagrantConfigFooter = "\nend   ## end of Vagrant configuration block\n"
  end

  def Generator.roleFileName(path, role)
    return path+'/'+role+'.json'
  end

  def Generator.vagrantFooter
    return "\nend # End of generated content"
  end

  def Generator.writeFile(name, content)
    IO.write(name, content)
  end

  def Generator.sshPtyOption(ssh_pty)
    ssh_pty_option = ''
    if ssh_pty == "true" || ssh_pty == "false"; 
      ssh_pty_option = "\tconfig.ssh.pty = " + ssh_pty
    end
    return ssh_pty_option
  end

  # Vagrantfile for Vbox provider
  def Generator.getVmDef(cookbook_path, name, host, boxurl, ssh_pty, vm_mem, template_path, provisioned)

    if template_path
      templatedef = "\t"+name+'.vm.synced_folder '+quote(template_path)+", "+quote('/home/vagrant/cnf_templates')
    else
      templatedef = ''
    end
    # ssh.pty option
    ssh_pty_option = sshPtyOption(ssh_pty)

    vmdef = "\n#  --> Begin definition for machine: " + name +"\n"\
            "\n"+'config.vm.define ' + quote(name) +' do |'+ name +"|\n" \
            + ssh_pty_option + "\n" \
            + "\t"+name+'.vm.box = ' + quote(boxurl) + "\n" \
            + "\t"+name+'.vm.hostname = ' + quote(host) + "\n" \
            + templatedef + "\n"
    if provisioned
      vmdef += "\t##--- Chef binding ---\n"\
            + "\t"+name+'.vm.provision '+ quote('chef_solo')+' do |chef| '+"\n" \
            + "\t\t"+'chef.cookbooks_path = '+ quote(cookbook_path)+"\n" \
            + "\t\t"+'chef.roles_path = '+ quote('.')+"\n" \
            + "\t\t"+'chef.add_role '+ quote(name) + "\n\tend"
    end

    if vm_mem
      vmdef += "\n\t"+'config.vm.provider :virtualbox do |vbox|' + "\n" \
               "\t\t"+'vbox.customize ["modifyvm", :id, "--memory", ' + quote(vm_mem) +"]\n\tend\n"
    end
    vmdef += "\nend #  <-- End of VM definition for machine: " + name +"\n\n"

    return vmdef
  end

  # Vagrantfile for Libvirt provider
  def Generator.getQemuDef(cookbook_path, name, host, boxurl, ssh_pty, template_path, provisioned)

    if template_path
      templatedef = "\t"+name+'.vm.synced_folder '+quote(template_path)+", "+quote('/home/vagrant/cnf_templates') \
                    +", type:"+quote('rsync')
    else
      templatedef = ''
    end
    # ssh.pty option
    ssh_pty_option = sshPtyOption(ssh_pty)

    qemudef = "\n#  --> Begin definition for machine: " + name +"\n"\
            + "\n"+'config.vm.define ' + quote(name) +' do |'+ name +"|\n" \
            + ssh_pty_option + "\n" \
            + "\t"+name+'.vm.box = ' + quote(boxurl) + "\n" \
            + "\t"+name+'.vm.hostname = ' + quote(host) + "\n" \
            + "\t"+name+'.vm.synced_folder '+quote('./')+", "+quote('/vagrant')+", type: "+quote('rsync')+"\n" \
            + templatedef + "\n"\
            + "\t"+name+'.vm.provider :libvirt do |qemu|' + "\n" \
            + "\t\t"+'qemu.driver = ' + quote('kvm') + "\n\tend"
    if provisioned
      qemudef += "\t##--- Chef binding ---\n"\
            + "\n\t"+name+'.vm.provision '+ quote('chef_solo')+' do |chef| '+"\n" \
            + "\t\t"+'chef.cookbooks_path = '+ quote(cookbook_path)+"\n" \
            + "\t\t"+'chef.roles_path = '+ quote('.')+"\n" \
            + "\t\t"+'chef.add_role '+ quote(name) + "\n\tend"
    end
    qemudef += "\nend #  <-- End of Qemu definition for machine: " + name +"\n\n"

    return qemudef
  end

  # Vagrantfile for Docker provider + Dockerfiles
  def Generator.getDockerDef(cookbook_path, name, ssh_pty, template_path, provisioned)

    if template_path
      templatedef = "\t"+name+'.vm.synced_folder '+quote(template_path)+", "+quote("/home/vagrant/cnf_templates")
    else
      templatedef = ""
    end
    # ssh.pty option
    ssh_pty_option = sshPtyOption(ssh_pty)


    dockerdef = "\n#  --> Begin definition for machine: " + name +"\n"\
            + "\n"+'config.vm.define ' + quote(name) +' do |'+ name +"|\n" \
            + ssh_pty_option + "\n" \
            + templatedef  + "\n" \
            + "\t"+name+'.vm.provider "docker" do |d|' + "\n" \
            + "\t\t"+'d.build_dir = ' + quote(name+"/") + "/\n" \
            + "\t\t"+'d.has_ssh = true' + "\n" \
            + "\t\t"+'d.privileged = true' + "\n\tend"
    if provisioned
      dockerdef += "\t##--- Chef binding ---\n"\
            + "\n\t"+name+'.vm.provision '+ quote('chef_solo')+' do |chef| '+"\n" \
            + "\t\t"+'chef.cookbooks_path = '+ quote(cookbook_path)+"\n" \
            + "\t\t"+'chef.roles_path = '+ quote('.')+"\n" \
            + "\t\t"+'chef.add_role '+ quote(name) + "\n\tend"
    end
    dockerdef += "\nend #  <-- End of Docker definition for machine: " + name +"\n\n"

    return dockerdef
  end
  # generate Dockerfiles
  def Generator.copyDockerfiles(path, name, platform, platform_version)
    # dir for Dockerfile
    node_path = path + "/" + name
    if Dir.exist?(node_path)
      $out.error "Folder already exists: " + node_path
    elsif
      #FileUtils.rm_rf(node_path)
      Dir.mkdir(node_path)
    end

    # TODO: make other solution, avoid multi IF
    # copy Dockerfiles to configuration dir nodes
    dockerfile_path = $session.mdbciDir+"/templates/dockerfiles/"
    case platform
      when "ubuntu"
        if platform_version == "trusty"
          dockerfile_path += "ubuntu/trusty/Dockerfile"
        else
          dockerfile_path += "ubuntu/precise/Dockerfile"
        end
      when "centos"
        if platform_version == "6"
          dockerfile_path += "centos/6/Dockerfile"
        elsif platform_version == "7"
          dockerfile_path += "centos/7/Dockerfile"
        end
      when "suse"
        # gen for suse
        p "Platform: " + platform.to_s
      else
        p "Platform: " + platform.to_s
    end

    FileUtils.cp_r dockerfile_path, node_path

  end

  #  Vagrantfile for AWS provider
  def Generator.getAWSVmDef(cookbook_path, name, boxurl, user, ssh_pty, instance_type, template_path, provisioned)

    if template_path
      mountdef = "\t" + name + ".vm.synced_folder " + quote(template_path) + ", " + quote("/home/vagrant/cnf_templates") + ", type: " + quote("rsync")
    else
      mountdef = ''
    end
    # ssh.pty option
    ssh_pty_option = sshPtyOption(ssh_pty)

    awsdef = "\n#  --> Begin definition for machine: " + name +"\n"\
           + "config.vm.define :"+ name +" do |" + name + "|\n" \
           + ssh_pty_option + "\n" \
           + "\t" + name + ".vm.provider :aws do |aws,override|\n" \
           + "\t\taws.ami = " + quote(boxurl) + "\n"\
           + "\t\taws.instance_type = " + quote(instance_type) + "\n" \
           + "\t\toverride.ssh.username = " + quote(user) + "\n" \
           + "\tend\n" \
           + mountdef + "\n"
    if provisioned
      awsdef += "\t##--- Chef binding ---\n"\
           + "\t" + name + ".vm.provision "+ quote('chef_solo')+" do |chef| \n"\
           + "\t\tchef.cookbooks_path = "+ quote(cookbook_path) + "\n" \
           + "\t\tchef.roles_path = "+ quote('.') + "\n" \
           + "\t\tchef.add_role "+ quote(name) + "\n" \
           + "\t\tchef.synced_folder_type = "+quote('rsync') + "\n\tend #<-- end of chef binding\n"
    end
    awsdef +="\nend #  <-- End AWS definition for machine: " + name +"\n\n"

    return awsdef
  end


  def Generator.getRoleDef(name, product, box)

    errorMock = "#NONE, due invalid repo name \n"
    role = Hash.new
    productConfig = Hash.new
    product_name = nil
    repoName = nil
    repo = nil

    if !product['repo'].nil?

      repoName = product['repo']

      $out.info "Repo name: "+repoName

      unless $session.repos.knownRepo?(repoName)
        $out.warning 'Unknown key for repo '+repoName+' will be skipped'
        return errorMock
      end

      $out.info 'Repo specified ['+repoName.to_s+'] (CORRECT), other product params will be ignored'
      repo = $session.repos.getRepo(repoName)

      product_name = $session.repos.productName(repoName)
    else
      product_name = product['name']
    end

    # TODO: implement support of multiple recipes in role file
    if product_name != 'packages'
      recipe_name = $session.repos.recipeName(product_name)

      $out.info 'Recipe '+recipe_name.to_s

      if repo.nil?
        repo = $session.repos.findRepo(product_name, product, box)
      end

      if repo.nil?
        return errorMock
      end

      config = Hash.new
      # edit recipe attributes in role
      config['version'] = repo['version']
      config['repo'] = repo['repo']
      config['repo_key'] = repo['repo_key']
      if !product['cnf_template'].nil? && !product['cnf_template_path'].nil?
        config['cnf_template'] = product['cnf_template']
        config['cnf_template_path'] = product['cnf_template_path']
      end
      if !product['node_name'].nil?
        config['node_name'] = product['node_name']
      end
      productConfig[product_name] = config

      role['name'] = name
      role['default_attributes'] = {}
      role['override_attributes'] = productConfig
      role['json_class'] = 'Chef::Role'
      role['description'] = 'MariaDb instance install and run'
      role['chef_type'] = 'role'
      role['run_list'] = ['recipe['+recipe_name+']']
    else
      recipe_name = $session.repos.recipeName(product_name)
      $out.info 'Recipe '+recipe_name.to_s

      role['name'] = name
      role['default_attributes'] = {}
      role['override_attributes'] = {}
      role['json_class'] = 'Chef::Role'
      role['description'] = 'packages recipe for all nodes'
      role['chef_type'] = 'role'
      role['run_list'] = ['recipe['+recipe_name+']']
    end

    roledef = JSON.pretty_generate(role)

    return roledef

    #todo uncomment
    if false

      # TODO: form string for several box recipes for maridb, maxscale, mysql

      roledef = '{ '+"\n"+' "name" :' + quote(name)+",\n"+ \
        <<-EOF
        "default_attributes": { },
      EOF

      roledef += " #{quote('override_attributes')}: { #{quote(package)}: #{mdbversion} },\n"

      roledef += <<-EOF
        "json_class": "Chef::Role",
        "description": "MariaDb instance install and run",
        "chef_type": "role",
      EOF
      roledef += quote('run_list') + ": [ " + quote("recipe[" + recipe_name + "]") + " ]\n"
      roledef += "}"
    end

  end

def Generator.checkPath(path, override)
    if Dir.exist?(path) && !override
      $out.error 'Folder already exists: ' + path
      $out.error 'Please specify another name or delete'
      exit -1
    end
    FileUtils.rm_rf(path)
    Dir.mkdir(path)
  end

  def Generator.boxValid?(box, boxes)
    if !box.empty?
      !boxes.getBox(box).nil?
    end
  end

  def Generator.nodeDefinition(node, boxes, path, cookbook_path)

    vm_mem = node[1]['memory_size'].nil? ? '1024' : node[1]['memory_size']

    # cookbook path dir
    if node[0]['cookbook_path']
      cookbook_path = node[1].to_s
    end

    # configuration parameters
    name = node[0].to_s
    host = node[1]['hostname'].to_s

    $out.info 'Requested memory ' + vm_mem

    box = node[1]['box'].to_s
    if !box.empty?
      box_params = boxes.getBox(box)

      provider = box_params['provider'].to_s
      case provider
        when 'aws'
          amiurl = box_params['ami'].to_s
          user = box_params['user'].to_s
          instance = box_params['default_instance_type'].to_s
          $out.info 'AWS definition for host:'+host+', ami:'+amiurl+', user:'+user+', instance:'+instance
        when 'mdbci'
          box_params.each do |key, value|
            $session.nodes[key] = value
          end
          $out.info 'MDBCI definition for host:'+host+', with parameters: ' + $session.nodes.to_s
        else
          boxurl = box_params['box'].to_s
          platform = box_params['platform'].to_s
          platform_version = box_params['platform_version'].to_s
      end
      # ssh_pty option
      if !box_params['ssh_pty'].nil?
        ssh_pty = box_params['ssh_pty']
        $out.info 'config.ssh.pty option is ' + ssh_pty.to_s + ' for a box ' + box.to_s
      end
    end

    provisioned = !node[1]['product'].nil?
    if (provisioned)
      product = node[1]['product']
      if !product['cnf_template_path'].nil?
        template_path = product['cnf_template_path']
      end
    end

    # generate node definition and role
    machine = ''
    if Generator.boxValid?(box, boxes)
      case provider
        when 'virtualbox'
          machine = getVmDef(cookbook_path, name, host, boxurl, ssh_pty, vm_mem, template_path, provisioned)
        when 'aws'
          machine = getAWSVmDef(cookbook_path, name, amiurl, user, ssh_pty, instance, template_path, provisioned)
        when 'libvirt'
          machine = getQemuDef(cookbook_path, name, host, boxurl, ssh_pty, template_path, provisioned)
        when 'docker'
          machine = getDockerDef(cookbook_path, name, ssh_pty, template_path, provisioned)
          copyDockerfiles(path, name, platform, platform_version)
        else
          $out.warning 'Configuration type invalid! It must be vbox, aws, libvirt or docker type. Check it, please!'
      end
    else
      $out.warning 'Box '+box+'is not installed or configured ->SKIPPING'
    end

    # box with mariadb, maxscale provision - create role
    if provisioned
      $out.info 'Machine '+name+' is provisioned by '+product.to_s
      role = getRoleDef(name, product, box)
      IO.write(roleFileName(path, name), role)
    end

    return machine
  end

  def Generator.generate(path, config, boxes, override, provider)

    #TODO Errors check
    exit_code = 1

    #TODO MariaDb Version Validator

    checkPath(path, override)

    cookbook_path = '../recipes/cookbooks/' # default cookbook path
    unless (config['cookbook_path'].nil?)
      cookbook_path = config['cookbook_path']
    end

    $out.info 'Global cookbook_path = ' + cookbook_path
    $out.info 'Nodes provider = ' + provider

    vagrant = File.open(path+'/Vagrantfile', 'w')

    vagrant.puts vagrantFileHeader

    unless ($session.awsConfigOption.to_s.empty?)
      # Generate AWS Configuration
      vagrant.puts Generator.awsProviderConfigImport($session.awsConfigOption)
      vagrant.puts Generator.vagrantConfigHeader

      vagrant.puts Generator.awsProviderConfig

      config.each do |node|
        $out.info 'Generate AWS Node definition for ['+node[0]+']'
        vagrant.puts Generator.nodeDefinition(node, boxes, path, cookbook_path)
      end
      vagrant.puts Generator.vagrantConfigFooter
    else
        # Generate VBox/Qemu Configuration
        vagrant.puts Generator.vagrantConfigHeader
        vagrant.puts Generator.providerConfig

        config.each do |node|
          unless (node[1]['box'].nil?)
            $out.info 'Generate VBox|Libvirt|Docker Node definition for ['+node[0]+']'
            vagrant.puts Generator.nodeDefinition(node, boxes, path, cookbook_path)
          end
        end
        vagrant.puts Generator.vagrantConfigFooter
    end

    if !File.size?(path+'/Vagrantfile') # nil if empty and not exist
      exit_code = 0
    else
      $out.warning 'Generated Vagrantfile is empty! Please check configuration file and regenerate it.'
      exit_code = 1
    end

    vagrant.close

    return exit_code
  end

end

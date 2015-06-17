require_relative '../core/out'


class Generator

  def Generator.quote(string)
    return '"'+string+'"'
  end

  def Generator.vagrantHeader(aws_config)

    if aws_config.to_s.empty?
      hdr = <<-EOF
# !! Generated content, do not edit !!
# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|

#Network autoconfiguration
config.vm.network "private_network", type: "dhcp"

    EOF
    else
      hdr = <<-EOF
# !! Generated content, do not edit !!
# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'yaml'

# Load AWS config file
      EOF
      hdr += 'if File.exist?(' + quote(aws_config.to_s) + ")\n"
      hdr += 'aws_config = YAML.load_file(' + quote(aws_config.to_s) + ")['aws']\n"
      hdr += "end\n"
      hdr += <<-EOF

Vagrant.configure(2) do |config|

config.vm.synced_folder ".", "/vagrant", type: "rsync"

      EOF
    end

    return hdr
  end

  def Generator.roleFileName(path,role)
    return path+'/'+role+'.json'
  end

  def Generator.vagrantFooter
    return "\nend # End of generated content"
  end

  def Generator.writeFile(name,content)
    IO.write(name,content)
  end

  def Generator.getVmDef(cookbook_path, name, host, box, boxurl, provisioned)

    if provisioned
      vmdef = "\n"+'config.vm.define ' + quote(name) +' do |'+ name +"|\n" \
            + "\t"+name+'.vm.box = ' + quote(boxurl) + "\n" \
            + "\t"+name+'.vm.hostname = ' + quote(host) +"\n" \
            + "\t"+name+'.vm.provision '+ quote('chef_solo')+' do |chef| '+"\n" \
            + "\t\t"+'chef.cookbooks_path = '+ quote(cookbook_path)+"\n" \
            + "\t\t"+'chef.roles_path = '+ quote('.')+"\n" \
            + "\t\t"+'chef.add_role '+ quote(name) + "\n\tend\nend\n"
    else
      vmdef = 'config.vm.define ' + quote(name) +' do |'+ name +"|\n" \
            + "\t"+name+'.vm.box = ' + quote(boxurl) + "\n" \
            + "\t"+name+'.vm.hostname = ' + quote(host) +"\nend\n"
    end

    return vmdef
  end
  #
  def Generator.getAWSVmDef(name, cookbook_path, ami, user_data)
    awsdef = 'config.vm.provider :aws do |'+ name +", override|\n" \
           + "\t"+name+'.access_key_id = aws_config["access_key_id"]' + "\n" \
           + "\t"+name+'.secret_access_key = aws_config["secret_access_key"]' + "\n" \
           + "\t"+name+'.keypair_name = aws_config["keypair_name"]' + "\n" \
           + "\t"+name+'.ami = ' + quote(ami) + "\n" \
           + "\t"+name+'.region = aws_config["region"]' + "\n" \
           + "\t"+name+'.security_groups = aws_config["security_groups"]' + "\n" \
           + "\t"+name+'.user_data = ' + quote(user_data) + "\n" \
           + "\n" \
           + "\t"+'override.vm.box = "dummy"' + "\n" \
           + "\t"+'override.vm.box_url = "https://github.com/mitchellh/vagrant-aws/raw/master/dummy.box"' + "\n" \
           + "\t"+'override.ssh.username = "ec2-user"' + "\n" \
           + "\t"+'override.ssh.private_key_path = aws_config["pemfile"]' + "\n" \
           + "\n" \
           + "\t"+'config.vm.provision '+ quote('chef_solo')+' do |chef|' + "\n" \
           + "\t\t"+'chef.cookbooks_path = '+ quote(cookbook_path) + "\n" \
           + "\t\t"+'chef.roles_path = '+ quote('.') + "\n" \
           + "\t\t"+'chef.add_role '+ quote(name) + "\n" \
           + "\t\t"+'chef.synced_folder_type = "rsync"' + "\n\tend\nend\n"

    return awsdef
  end

  def Generator.getRoleDef(name,package,params)

    if params.class == Hash
      mdbversion = JSON.pretty_generate(params)
    else
      mdbversion = '{ '+ "version"+':'+quote(params)+' }'
    end
    # package recipe name
    if package == 'mariadb'
      recipe_name = 'mdbc'
    else
      recipe_name = 'mscale'
    end

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

    return roledef
  end

  #TODO: Delete?
  def Generator.makeDefinition(name, host, box, boxurl, version)

    #vm = getVmDef(name, host, box, boxurl)
    #role = getRoleDef(name,version)

    #writeFile('.Vagrantfile',vmdef)
    #puts vm
    #puts role
  end

  def Generator.checkPath(path,override)
    if Dir.exist?(path) && !override
      $out.error 'ERR: folder already exists:' + path
      $out.error 'Please specify another name or delete'
      exit -1
    end
    FileUtils.rm_rf(path)
    Dir.mkdir(path)
  end

  def Generator.boxValid?(box,boxes)
    !boxes[box].nil?
  end

  def Generator.amiValid?(ami,boxes)
    !boxes[ami].nil?
  end

  def Generator.generate(path, config, boxes, override, aws_config)
    #TODO Errors check
    #TODO MariaDb Version Validator

    checkPath(path,override)

    vagrant = File.open(path+'/Vagrantfile','w')

    vagrant.puts vagrantHeader(aws_config)

    cookbook_path = './recipes/cookbooks/'  # default cookbook path
    vm_provision = ''                       # vm provisioner: aws, qemu
    provisioned = true                      # default provision option

    config.each do |node|
      $out.info node[0].to_s + ':' + node[1].to_s
      # cookbook path dir
      if node[0]['cookbook_path']
        cookbook_path = node[1].to_s
      end
      # vm_provision
      if node[0]['vm_provision']
        vm_provision = node[1].to_s
      end
      # configuration parameters
      box = node[1]['box'].to_s
      boxurl = boxes[box]
      name = node[0].to_s
      host = node[1]['hostname'].to_s
      # package: mariadb or maxscale
      if node[1]['mariadb']
        package = 'mariadb'
        params = node[1]['mariadb']
        provisioned = true
      elsif node[1]['maxscale']
        package = 'maxscale'
        params = node[1]['maxscale']
        provisioned = true
      else
        provisioned = false
      end
      # aws node configuration
      if node[1]['aws']
        ami = node[1]['aws']['ami']
        amiurl = boxes[ami]
        user_data = node[1]['aws']['user_data']
      end

      # generate node definition and role
      if vm_provision == '' # virtualbox
        if Generator.boxValid?(box,boxes)
          vm = getVmDef(cookbook_path,name,host,box,boxurl,provisioned)
          vagrant.puts vm
          # refactoring
          # box with mariadb, maxscale provision - create role
          if provisioned
            role = getRoleDef(name,package,params)
            IO.write(roleFileName(path,name),role)
          end
        else
          $out.warning 'WARNING: Box '+box+'is not installed or configured ->SKIPPING'
        end
      elsif vm_provision == 'aws'
        if Generator.amiValid?(ami,boxes)
          aws = getAWSVmDef(name, cookbook_path, amiurl, user_data)
          vagrant.puts aws
          # refactoring
          # box with mariadb, maxscale provision - create role
          if provisioned
            role = getRoleDef(name,package,params)
            IO.write(roleFileName(path,name),role)
          end
        else
          $out.warning 'WARNING: AWS AMI '+ami.to_s+'is not installed or configured ->SKIPPING'
        end
      else
        $out.warning 'WARNING: Configuration has not AWS support|config file or other vm provision'
      end

      #makeDefinition(node[0].to_s,node[1]['hostname'].to_s,box,boxurl,node[1]['mariadb'])
    end
    vagrant.puts vagrantFooter
    vagrant.close
  end
end
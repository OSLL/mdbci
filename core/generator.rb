require_relative '../core/out'


class Generator

  def Generator.vagrantHeader
    hdr = <<-EOF
# !! Generated content, do not edit !!

Vagrant.configure(2) do |config|

#Network autoconfiguration
config.vm.network "private_network", type: "dhcp"

    EOF
    return hdr
  end

  def Generator.roleFileName(path,role)
    return path+'/'+role+'.json'
  end

  def Generator.vagrantFooter
    return "\n end # End of generated content"
  end

  def Generator.quote(string)
    return '"'+string+'"'
  end

  def Generator.writeFile(name,content)
    IO.write(name,content)
  end

  def Generator.getVmDef(name, host, box, boxurl)
    vmdef = 'config.vm.define ' + quote(name) +' do |'+ name +"|\n" \
          + name+'.vm.box = ' + quote(boxurl) + "\n" \
          + name+'.vm.hostname = ' + quote(host) +"\n" \
          + name+'.vm.provision '+ quote('chef_solo')+' do |chef| '+"\n" \
          + 'chef.cookbooks_path = '+ quote('../recipes/cookbooks')+"\n" \
          + 'chef.roles_path = '+ quote('.')+"\n" \
          + 'chef.add_role '+ quote(name) + "\nend\nend\n"
    return vmdef
  end

  def Generator.getRoleDef(name,version)

    if version.class == Hash
      mdbversion = JSON.pretty_generate(version)
    else
      mdbversion = '{ '+quote('version')+':'+quote(version)+' }'
    end

    roledef = '{ '+"\n"+' "name" :' + quote(name)+",\n"+ \
    <<-EOF
 "default_attributes": { },
    EOF
    roledef += ' '+quote('override_attributes') +': { '+quote('maria')+ ': '+ mdbversion +\
    ' },'+"\n"
    roledef += <<-EOF
 "json_class": "Chef::Role",
 "description": "MariaDb instance install and run",
 "chef_type": "role",
 "run_list": [ "recipe[mdbc]" ]
}
    EOF
    return roledef
  end

  #TODO: Delete?
  def Generator.makeDefinition(name, host, box, boxurl, version)


    vm = getVmDef(name, host, box, boxurl)
    role = getRoleDef(name,version)

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
    FileUtils.rm_rf(path);
    Dir.mkdir(path)
  end

  def Generator.boxValid?(box,boxes)
    !boxes[box].nil?
  end

  def Generator.generate(path, config, boxes, override)
    #TODO Errors check
    #TODO MariaDb Version Validator

    checkPath(path,override)

    vagrant = File.open(path+'/Vagrantfile','w')

    vagrant.puts vagrantHeader

    config.each do |node|
      $out.info node[0].to_s + ':' + node[1].to_s
      box = node[1]['box'].to_s
      boxurl = boxes[box]
      name = node[0].to_s
      host = node[1]['hostname'].to_s
      version = node[1]['mariadb']


      if Generator.boxValid?(box,boxes)
        vm = getVmDef(name,host,box,boxurl)
        vagrant.puts vm
        role = getRoleDef(name,version)
        IO.write(roleFileName(path,name),role)
      else
        $out.error 'ERR: Box '+box+'is not installed or configured ->SKIPPING'
      end
      #makeDefinition(node[0].to_s,node[1]['hostname'].to_s,box,boxurl,node[1]['mariadb'])
    end
    vagrant.puts vagrantFooter
    vagrant.close
  end
end
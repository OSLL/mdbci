class Generator

  def Generator.vagrantHeader
    hdr = <<-EOF
#Generated content, do not edit
Vagrant.configure(2) do |config|

    EOF
    return hdr
  end

  def Generator.roleFileName(role)
    return 'recipes/roles/'+role+'.json'
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
          + name+'.vm.box = ' + quote(box) + "\n" \
          + name+'.vm.box_url = ' + quote(boxurl) + "\n" \
          + name+'.vm.hostname = ' + quote(host) +"\n" \
          + name+'.vm.provision '+ quote('chef_solo')+' do |chef| '+"\n" \
          + 'chef.cookbooks_path = '+ quote('recipes/cookbooks')+"\n" \
          + 'chef.roles_path = '+ quote('recipes/roles')+"\n" \
          + 'chef.add_role '+ quote(name) + "\nend\nend\n"
    return vmdef
  end

  def Generator.getRoleDef(name,version)
    roledef = '{ '+"\n"+' "name" :' + quote(name)+"\n"+ \
    <<-EOF
 "default_attributes": { },
    EOF
    roledef += ' '+quote('override_attributes') +': { '+quote('maria')+\
        ': { '+quote('version')+':'+quote(version)+' } },'+"\n"
    roledef += <<-EOF
 "json_class": "Chef::Role",
 "description": "MariaDb instance install and run",
 "chef_type": "role",
 "run_list": [ "recipe[mdbc]" ]
}
    EOF
    return roledef
  end

  def Generator.makeDefinition(name, host, box, boxurl, version)
    vm = getVmDef(name, host, box, boxurl)
    role = getRoleDef(name,version)

    #writeFile('.Vagrantfile',vmdef)
    #puts vm
    #puts role
  end

  def Generator.generate(config, boxes)
    #TODO Errors check

    vagrant = File.open('Vagrantfile','w')

    vagrant.puts vagrantHeader

    config.each do |node|
      puts node[0].to_s + ':' + node[1].to_s
      box = node[1]['box'].to_s
      boxurl = boxes[box]
      name = node[0].to_s
      host = node[1]['hostname'].to_s
      version = node[1]['mariadb']


      vm = getVmDef(name,host,box,boxurl)
      vagrant.puts vm

      role = getRoleDef(name,version)
      IO.write(roleFileName(name),role)


      #makeDefinition(node[0].to_s,node[1]['hostname'].to_s,box,boxurl,node[1]['mariadb'])
    end
    vagrant.puts vagrantFooter
    vagrant.close
  end
end
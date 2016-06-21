copycmd = 'cp /home/vagrant/cnf_templates/' + node['test']['cnf_template'] + ' /home/vagrant/'
execute "Copy mdbci_server.cnf to cnf_template directory" do
  command copycmd
end
task :run_unit_parametrized do

  task :task_6639_ssh_exit_code, [:pathToConfigToVBOXNode, :pathToConfigToMDBCINode, :pathToConfigToMDBCIFolder, :pathToConfigToMDBCINode] do |t, args| RakeTaskManager.new(t).run_parametrized(args) end
  task :task_6640_sudo_exit_code, [:pathToConfigToVBOXNode] do |t, args| RakeTaskManager.new(t).run_parametrized(args) end
  task :task_6641_setup_exit_code, [:pathToTestBoxes, :testBoxName] do |t, args| RakeTaskManager.new(t).run_parametrized(args) end
  task :task_6642_show_keyfile_exit_code, [:pathToConfigToVBOXNode, :pathToConfigToMDBCINode, :pathToConfigToMDBCIFolder, :pathToConfigToMDBCINode] do |t, args| RakeTaskManager.new(t).run_parametrized(args) end
  task :task_6643_show_network_exit_code, [:pathToConfigToVBOXNode, :pathToConfigToMDBCINode, :pathToConfigToMDBCIFolder, :pathToConfigToMDBCINode] do |t, args| RakeTaskManager.new(t).run_parametrized(args) end
  task :task_6644_show_private_ip_exit_code, [:pathToConfigToVBOXNode, :pathToConfigToMDBCINode, :pathToConfigToMDBCIFolder, :pathToConfigToMDBCINode] do |t, args| RakeTaskManager.new(t).run_parametrized(args) end
  task :task_6645_public_keys_exit_code, [:pathToConfigToVBOXNode, :pathToConfigToMDBCINode, :pathToConfigToMDBCIFolder, :pathToConfigToMDBCINode] do |t, args| RakeTaskManager.new(t).run_parametrized(args) end
  task :task_6648_generate_exit_code, [:pathToVBOXConfigFile, :pathToMDBCIConfigFile, :pathToDestination] do |t, args| RakeTaskManager.new(t).run_parametrized(args) end

  Rake::Task[:task_6639_ssh_exit_code].execute({ :pathToConfigToVBOXNode=>'TEST/vboxnode', :pathToConfigToMDBCINode=>'TEST1/mdbcinode', :pathToConfigToMDBCIBadNode=>'TEST2/mdbcinodebad', :pathToConfigToMDBCIFolder=>'TEST1' })
  Rake::Task[:task_6640_sudo_exit_code].execute({ :pathToConfigToVBOXNode=>'TEST/vboxnode' })
  Rake::Task[:task_6641_setup_exit_code].execute( {:pathToTestBoxes=>'TESTBOXES', :testBoxName=>'testbox'} )
  Rake::Task[:task_6642_show_keyfile_exit_code].execute({ :pathToConfigToVBOXNode=>'TEST/vboxnode', :pathToConfigToMDBCINode=>'TEST1/mdbcinode', :pathToConfigToMDBCIBadNode=>'TEST2/mdbcinodebad', :pathToConfigToMDBCIFolder=>'TEST1' })
  Rake::Task[:task_6643_show_network_exit_code].execute({ :pathToConfigToVBOXNode=>'TEST/vboxnode', :pathToConfigToMDBCINode=>'TEST1/mdbcinode', :pathToConfigToMDBCIBadNode=>'TEST3/mdbcinodebad', :pathToConfigToMDBCIFolder=>'TEST1' })
  Rake::Task[:task_6644_show_private_ip_exit_code].execute({ :pathToConfigToVBOXNode=>'TEST/vboxnode', :pathToConfigToMDBCINode=>'TEST1/mdbcinode', :pathToConfigToMDBCIBadNode=>'TEST3/mdbcinodebad', :pathToConfigToMDBCIFolder=>'TEST1' })
  Rake::Task[:task_6645_public_keys_exit_code].execute({ :pathToConfigToVBOXNode=>'TEST/vboxnode', :pathToConfigToMDBCINode=>'TEST1/mdbcinode', :pathToConfigToMDBCIBadNode=>'TEST3/mdbcinodebad', :pathToConfigToMDBCIFolder=>'TEST1' })
  Rake::Task[:task_6648_generate_exit_code].execute({ :pathToVBOXConfigFile=>'spec/test_machine_configurations/vbox.json', :pathToMDBCIConfigFile=>'spec/test_machine_configurations/mdbci.json', :pathToDestination=>'TEST_GEN' })

  RakeTaskManager.get_failed_tests_info
end

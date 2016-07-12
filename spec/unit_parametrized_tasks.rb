task :run_unit_parametrized do

  task :task_6639_ssh_exit_code, [:pathToConfigToVBOXNode, :pathToConfigToMDBCINode, :pathToConfigToMDBCIFolder, :pathToConfigToMDBCINode] do |t, args| RakeTaskManager.new(t).run_parametrized(args) end
  task :task_6640_sudo_exit_code, [:pathToConfigToVBOXNode] do |t, args| RakeTaskManager.new(t).run_parametrized(args) end
  task :task_6641_setup_exit_code, [:pathToTestBoxes, :testBoxName] do |t, args| RakeTaskManager.new(t).run_parametrized(args) end
  task :task_6642_show_keyfile_exit_code, [:pathToConfigToVBOXNode, :pathToConfigToMDBCINode, :pathToConfigToMDBCIFolder, :pathToConfigToMDBCINode] do |t, args| RakeTaskManager.new(t).run_parametrized(args) end
  task :task_6643_show_network_exit_code, [:pathToConfigToVBOXNode, :pathToConfigToMDBCINode, :pathToConfigToMDBCIFolder, :pathToConfigToMDBCINode] do |t, args| RakeTaskManager.new(t).run_parametrized(args) end
  task :task_6644_show_private_ip_exit_code, [:pathToConfigToVBOXNode, :pathToConfigToMDBCINode, :pathToConfigToMDBCIFolder, :pathToConfigToMDBCINode] do |t, args| RakeTaskManager.new(t).run_parametrized(args) end
  task :task_6645_public_keys_exit_code, [:pathToConfigToVBOXNode, :pathToConfigToMDBCINode, :pathToConfigToMDBCIFolder, :pathToConfigToMDBCINode] do |t, args| RakeTaskManager.new(t).run_parametrized(args) end
  task :task_6803_showKeyFile_exceptions, [:pathToVboxFolder] do |t, args| RakeTaskManager.new(t).run_parametrized(args) end
  task :task_6821_show_box_config_node, [:pathToConfigNode, :pathToConfig] do |t, args| RakeTaskManager.new(t).run_parametrized(args) end
  task :task_6818_search_box_name_by_config, [:configPath, :nodeName] do |t, args| RakeTaskManager.new(t).run_parametrized(args) end
  task :task_7159_main_cloning_func_check_provider, [:pathToConfigToMDBCILibvirtProviderNode, :pathToConfigToMDBCIDockerProviderNode, :pathToConfigToMDBCIBadNode] do |t, args| RakeTaskManager.new(t).run_parametrized(args) end
  task :task_7144_copying_old_config_to_new, [:pathToOldNotExistingConfig, :pathToOldValidConfigWithoutValidNode, :pathToOldValidConfig, :pathToNotValidNewConfig, :pathToValidNewConfig] do |t, args| RakeTaskManager.new(t).run_parametrized(args) end


  Rake::Task[:task_6639_ssh_exit_code].execute({ :pathToConfigToVBOXNode=>'TEST/vboxnode', :pathToConfigToMDBCINode=>'TEST1/mdbcinode', :pathToConfigToMDBCIBadNode=>'TEST2/mdbcinodebad', :pathToConfigToMDBCIFolder=>'TEST1' })
  Rake::Task[:task_6640_sudo_exit_code].execute({ :pathToConfigToVBOXNode=>'TEST/vboxnode' })
  Rake::Task[:task_6641_setup_exit_code].execute( {:pathToTestBoxes=>'TESTBOXES', :testBoxName=>'testbox'} )
  Rake::Task[:task_6642_show_keyfile_exit_code].execute({ :pathToConfigToVBOXNode=>'TEST/vboxnode', :pathToConfigToMDBCINode=>'TEST1/mdbcinode', :pathToConfigToMDBCIBadNode=>'TEST2/mdbcinodebad', :pathToConfigToMDBCIFolder=>'TEST1' })
  Rake::Task[:task_6643_show_network_exit_code].execute({ :pathToConfigToVBOXNode=>'TEST/vboxnode', :pathToConfigToMDBCINode=>'TEST1/mdbcinode', :pathToConfigToMDBCIBadNode=>'TEST3/mdbcinodebad', :pathToConfigToMDBCIFolder=>'TEST1' })
  Rake::Task[:task_6644_show_private_ip_exit_code].execute({ :pathToConfigToVBOXNode=>'TEST/vboxnode', :pathToConfigToMDBCINode=>'TEST1/mdbcinode', :pathToConfigToMDBCIBadNode=>'TEST3/mdbcinodebad', :pathToConfigToMDBCIFolder=>'TEST1' })
  Rake::Task[:task_6645_public_keys_exit_code].execute({ :pathToConfigToVBOXNode=>'TEST/vboxnode', :pathToConfigToMDBCINode=>'TEST1/mdbcinode', :pathToConfigToMDBCIBadNode=>'TEST3/mdbcinodebad', :pathToConfigToMDBCIFolder=>'TEST1' })
  Rake::Task[:task_6803_showKeyFile_exceptions].execute({ :pathToVboxFolder=>'TEST' })
  Rake::Task[:task_6821_show_box_config_node].execute({ :pathToConfigNode=>'TEST/vboxnode', :pathToConfig=>'TEST' })
  Rake::Task[:task_6818_search_box_name_by_config].execute({ :configPath=>'confs/mdbci_up_aws_test_config.json', :nodeName=>'galera0' })
  Rake::Task[:task_7159_main_cloning_func_check_provider].execute({ :pathToConfigToMDBCILibvirtProviderNode=>'TEST0/node0', :pathToConfigToMDBCIDockerProviderNode=>'TEST1/node0', :pathToConfigToMDBCIBadNode=>'TEST2/node0' })
  Rake::Task[:task_7144_copying_old_config_to_new].execute({ :pathToOldNotExistingConfig=>'not_valid_catalog', :pathToOldValidConfigWithoutValidNode=>'TEST', :pathToOldValidConfig=>'TEST0', :pathToNotValidNewConfig=>'TEST1', :pathToValidNewConfig=>'TEST2' })

  RakeTaskManager.get_failed_tests_info
end

task :run_integration_parametrized do

  task :task_6646_setup_repo_exit_code, [:pathToConfigToVBOXNode, :pathToConfigToMDBCINode, :pathToConfigToMDBCIFolder, :pathToConfigToMDBCINode] do |t, args| RakeTaskManager.new(t).run_integration_parametrized(args) end
  task :task_6647_install_product_exit_code, [:pathToConfigToVBOXNode, :pathToConfigToMDBCINode, :pathToConfigToMDBCIFolder, :pathToConfigToMDBCINode] do |t, args| RakeTaskManager.new(t).run_integration_parametrized(args) end
  task :task_6970_show_box_exit_code, [:pathToConfigNode, :pathToConfig] do |t, args| RakeTaskManager.new(t).run_integration_parametrized(args) end

  Rake::Task[:task_6646_setup_repo_exit_code].execute({ :pathToConfigToVBOXNode=>'TEST/vboxnode', :pathToConfigToVBOXFolder=>'TEST', :pathToConfigToMDBCINode=>'TEST1/mdbcinode', :pathToConfigToMDBCIBadNode=>'TEST2/mdbcinodebad', :pathToConfigToMDBCIFolder=>'TEST1' })
  Rake::Task[:task_6647_install_product_exit_code].execute({ :pathToConfigToVBOXNode=>'TEST/vboxnode', :pathToConfigToMDBCINode=>'TEST1/mdbcinode', :pathToConfigToMDBCIBadNode=>'TEST2/mdbcinodebad', :pathToConfigToMDBCIFolder=>'TEST1' })
  Rake::Task[:task_6970_show_box_exit_code].execute({ :pathToConfigNode=>'TEST/vboxnode', :pathToConfig=>'TEST' })

  RakeTaskManager.get_failed_tests_info
end

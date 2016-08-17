namespace :run_unit_parametrized do

# TESTS NOT NEED TO BRING UP MACHINES
=begin 
  task :task_6641_setup_exit_code, [:pathToTestBoxes, :testBoxName] do |t, args| RakeTaskManager.new(t).run_parametrized(args) end
  task :task_6818_search_box_name_by_config, [:configPath, :nodeName] do |t, args| RakeTaskManager.new(t).run_parametrized(args) end
=end


# TESTS THAT NOT FOUND OR NOT IMPORTANT AT THE MOMENT
=begin
  task :task_6803_showKeyFile_exceptions, [:pathToVboxFolder] do |t, args| RakeTaskManager.new(t).run_parametrized(args) end
  task :task_6639_ssh_exit_code, [:pathToConfigToVBOXNode, :pathToConfigToMDBCINode, :pathToConfigToMDBCIFolder, :pathToConfigToMDBCINode] do |t, args| RakeTaskManager.new(t).run_parametrized(args) end
  task :task_6642_show_keyfile_exit_code, [:pathToConfigToVBOXNode, :pathToConfigToMDBCINode, :pathToConfigToMDBCIFolder, :pathToConfigToMDBCINode] do |t, args| RakeTaskManager.new(t).run_parametrized(args) end
  task :task_6821_show_box_config_node, [:pathToConfigNode, :pathToConfig] do |t, args| RakeTaskManager.new(t).run_parametrized(args) end
=end

# TESTS WITH PROBLEMS
=begin
  task :task_7110_collectConfigurationNetworkInfo do |t| RakeTaskManager.new(t).run_unit_parametrized([LIBVIRT, PPC])  end
=end

  task :task_7222_testing_environment_check do |t| RakeTaskManager.new(t).run_unit_parametrized([DOCKER, LIBVIRT, PPC]) end
  task :task_7364_devide_param_test_by_config_docker do |t| RakeTaskManager.new(t).run_unit_parametrized([DOCKER]) end
  task :task_7364_devide_param_test_by_config_libvirt do |t| RakeTaskManager.new(t).run_unit_parametrized([LIBVIRT]) end
  task :task_7364_devide_param_test_by_config_ppc do |t| RakeTaskManager.new(t).run_unit_parametrized([PPC]) end
  task :task_6640_sudo_exit_code do |t| RakeTaskManager.new(t).run_unit_parametrized([DOCKER, LIBVIRT]) end
  task :task_6644_show_private_ip_exit_code do |t| RakeTaskManager.new(t).run_unit_parametrized([LIBVIRT, PPC]) end
  task :task_6643_show_network_exit_code do |t| RakeTaskManager.new(t).run_unit_parametrized([LIBVIRT, PPC]) end
  task :task_6645_public_keys_exit_code do |t| RakeTaskManager.new(t).run_unit_parametrized([LIBVIRT, PPC]) end
  task :task_7159_main_cloning_func do |t| RakeTaskManager.new(t).run_unit_parametrized([LIBVIRT, DOCKER, PPC]) end

  task :task_show_tests_info do RakeTaskManager.get_failed_tests_info end

end

task :run_unit_parametrized_all do
  Rake.application.in_namespace(:run_unit_parametrized) do |x|
    x.tasks.each do |t|
      t.invoke
    end
  end
end
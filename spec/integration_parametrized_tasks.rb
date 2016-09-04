namespace :run_integration_parametrized do

  task :task_6646_setup_repo_for_conf_exit_code do |t| RakeTaskManager.new(t).run_integration_parametrized([DOCKER, PPC]) end
  task :task_6646_setup_repo_for_node_exit_code do |t| RakeTaskManager.new(t).run_integration_parametrized([DOCKER, PPC]) end
  task :task_6646_setup_repo_handling_exceptions_exit_code do |t| RakeTaskManager.new(t).run_integration_parametrized([DOCKER, PPC]) end
  task :task_6647_install_product_for_conf_exit_code do |t| RakeTaskManager.new(t).run_integration_parametrized([DOCKER, PPC]) end
  task :task_6647_install_product_for_node_exit_code do |t| RakeTaskManager.new(t).run_integration_parametrized([DOCKER, PPC]) end
  task :task_6647_install_product_handling_exceptions_exit_code do |t| RakeTaskManager.new(t).run_integration_parametrized([DOCKER, PPC]) end
  task :task_6970_show_box_config_node_exit_code do |t| RakeTaskManager.new(t).run_integration_parametrized([]) end
  task :task_7294_show_network_config do |t| RakeTaskManager.new(t).run_integration_parametrized([]) end
  task :task_7448_install_sysbench do |t| RakeTaskManager.new(t).run_integration_parametrized([]) end

end

RakeTaskManager.rake_finalize(:run_integration_parametrized)
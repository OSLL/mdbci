task :run_integration_parametrized do

  task :task_6646_setup_repo_exit_code, [:pathToConfigToVBOXNode, :pathToConfigToMDBCINode, :pathToConfigToMDBCIFolder, :pathToConfigToMDBCINode] do |t, args| RakeTaskManager.new(t).run_integration_parametrized(args) end
  task :task_6647_install_product_exit_code, [:pathToConfigToVBOXNode, :pathToConfigToMDBCINode, :pathToConfigToMDBCIFolder, :pathToConfigToMDBCINode] do |t, args| RakeTaskManager.new(t).run_integration_parametrized(args) end
  task :task_6970_show_box_exit_code, [:pathToConfigNode, :pathToConfig] do |t, args| RakeTaskManager.new(t).run_integration_parametrized(args) end
  task :task_7294_show_network_confi, [:pathToNetworkConfig] do |t, args| RakeTaskManager.new(t).run_integration_parametrized(args) end

  task :task_show_tests_info do RakeTaskManager.get_failed_tests_info end

end

task :run_integration_parametrized_all do
  Rake.application.in_namespace(:run_integration_parametrized) do |x|
    x.tasks.each do |t|
      t.invoke
    end
  end
end
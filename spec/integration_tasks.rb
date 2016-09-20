namespace :run_integration do

  task :task_shell_command_testing_example do |t| RakeTaskManager.new(t).run_integration end
  task :task_6819_show_box_info do |t| RakeTaskManager.new(t).run_integration end
  task :task_6782_show_commands_exit_code do |t| RakeTaskManager.new(t).run_integration end
  task :task_6648_generate_exit_code do |t| RakeTaskManager.new(t).run_integration end
  task :task_7425_sysbench_parser do |t| RakeTaskManager.new(t).run_integration end

  task :task_show_tests_info do RakeTaskManager.get_failed_tests_info end

end

RakeTaskManager.rake_finalize(:run_integration)
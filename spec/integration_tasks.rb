task :run_integration do

  task :task_shell_command_testing_example do |t| RakeTaskManager.new(t).run_integration end
  task :task_6819_show_box_info do |t| RakeTaskManager.new(t).run_integration end
  task :task_6782_show_commands_exit_code do |t| RakeTaskManager.new(t).run_integration end

  Rake::Task[:task_shell_command_testing_example].execute
  Rake::Task[:task_6819_show_box_info].execute
  Rake::Task[:task_6782_show_commands_exit_code].execute

  RakeTaskManager.get_failed_tests_info

end

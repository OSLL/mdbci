namespace :run_unit do

  task :task_generator do |t| RakeTaskManager.new(t).run_unit end
  task :task_6819_show_box_info do |t| RakeTaskManager.new(t).run_unit end
  task :task_6755_show_platform_versions do |t| RakeTaskManager.new(t).run_unit end
  task :task_6844_ssh_pty_bug do |t| RakeTaskManager.new(t).run_unit end
  task :task_6754_bug do |t| RakeTaskManager.new(t).run_unit end
  task :task_6783_show_boxes do |t| RakeTaskManager.new(t).run_unit end
  task :task_6813_divide_show_boxes do |t| RakeTaskManager.new(t).run_unit end
  task :task_node_product do |t| RakeTaskManager.new(t).run_unit end
  task :task_boxes_manager do |t| RakeTaskManager.new(t).run_unit end
  task :task_repos_manager do |t| RakeTaskManager.new(t).run_unit end
  task :task_session do |t| RakeTaskManager.new(t).run_unit end
  task :task_6812_show_repo_manager_exceptions do |t| RakeTaskManager.new(t).run_unit end
  task :task_6863_tests_for_6821_show_box do |t| RakeTaskManager.new(t).run_unit end
  task :task_7185_helper_functions do |t| RakeTaskManager.new(t).run_unit end
  task :task_7144_copying_old_config_to_new do |t| RakeTaskManager.new(t).run_unit end
  task :task_7154_refer_old_node_to_new do |t| RakeTaskManager.new(t).run_unit end
  task :task_7209_add_aws_tag do |t| RakeTaskManager.new(t).run_unit end
  task :task_6641_setup_exit_code do |t| RakeTaskManager.new(t).run_unit end
  task :task_6818_search_box_name_by_config do |t| RakeTaskManager.new(t).run_unit end
  task :task_7435_comments_in_pull_284 do |t| RakeTaskManager.new(t).run_unit  end
  task :task_show_tests_info do RakeTaskManager.get_failed_tests_info end
end

RakeTaskManager.rake_finalize(:run_unit)

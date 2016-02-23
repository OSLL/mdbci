require 'rake'
require_relative 'spec/rake_helper'

# here you need to add task with appropriate parameters
task :run_parametrized do
  Rake::Task[:task_6639_ssh_exit_code].execute({ :pathToConfigToVBOXNode=>'TEST/vboxnode', :pathToConfigToMDBCINode=>'TEST1/mdbcinode', :pathToConfigToMDBCIBadNode=>'TEST2/mdbcinodebad', :pathToConfigToMDBCIFolder=>'TEST1' })
  Rake::Task[:task_6640_sudo_exit_code].execute({ :pathToConfigToVBOXNode=>'TEST/vboxnode' })
  Rake::Task[:task_6641_setup_exit_code].execute( {:pathToTestBoxes=>'TESTBOXES', :testBoxName=>'testbox'} )
  Rake::Task[:task_6642_show_keyfile_exit_code].execute({ :pathToConfigToVBOXNode=>'TEST/vboxnode', :pathToConfigToMDBCINode=>'TEST1/mdbcinode', :pathToConfigToMDBCIBadNode=>'TEST2/mdbcinodebad', :pathToConfigToMDBCIFolder=>'TEST1' })
  Rake::Task[:task_6643_show_network_exit_code].execute({ :pathToConfigToVBOXNode=>'TEST/vboxnode', :pathToConfigToMDBCINode=>'TEST1/mdbcinode', :pathToConfigToMDBCIBadNode=>'TEST3/mdbcinodebad', :pathToConfigToMDBCIFolder=>'TEST1' })
  Rake::Task[:task_6644_show_private_ip_exit_code].execute({ :pathToConfigToVBOXNode=>'TEST/vboxnode', :pathToConfigToMDBCINode=>'TEST1/mdbcinode', :pathToConfigToMDBCIBadNode=>'TEST3/mdbcinodebad', :pathToConfigToMDBCIFolder=>'TEST1' })
  Rake::Task[:task_6645_public_keys_exit_code].execute({ :pathToConfigToVBOXNode=>'TEST/vboxnode', :pathToConfigToMDBCINode=>'TEST1/mdbcinode', :pathToConfigToMDBCIBadNode=>'TEST3/mdbcinodebad', :pathToConfigToMDBCIFolder=>'TEST1' })
  Rake::Task[:task_6646_setup_repo_exit_code].execute({ :pathToConfigToVBOXNode=>'TEST/vboxnode', :pathToConfigToVBOXFolder=>'TEST', :pathToConfigToMDBCINode=>'TEST1/mdbcinode', :pathToConfigToMDBCIBadNode=>'TEST2/mdbcinodebad', :pathToConfigToMDBCIFolder=>'TEST1' })
  Rake::Task[:task_6647_install_product_exit_code].execute({ :pathToConfigToVBOXNode=>'TEST/vboxnode', :pathToConfigToMDBCINode=>'TEST1/mdbcinode', :pathToConfigToMDBCIBadNode=>'TEST2/mdbcinodebad', :pathToConfigToMDBCIFolder=>'TEST1' })
  Rake::Task[:task_6648_generate_exit_code].execute({ :pathToVBOXConfigFile=>'spec/test_machine_configurations/vbox.json', :pathToMDBCIConfigFile=>'spec/test_machine_configurations/mdbci.json', :pathToDestination=>'TEST_GEN' })

  RakeTaskManager.get_failed_tests_info
end

# here will be tasks without parameters
task :run do
  Rake::Task[:task_generator].execute
  Rake::Task[:task_shell_command_testing_example].execute
<<<<<<< HEAD
  Rake::Task[:task_6819_show_box_info].execute
=======
  Rake::Task[:task_6782_show_commands_exit_code].execute
>>>>>>> origin/integration
  Rake::Task[:task_6755_show_platform_versions].execute

  RakeTaskManager.get_failed_tests_info
end

### EXAMPLE ###
# name of task can not start with digits, so it starts with 'task...'
# this task expecting argument which is hash {:pathToConfig=>'TEST', :vmType=>'mdbci'}
# keys and values will be added to ENV variable for one test then when test is executed
# those keys and values will be removed from ENV
# in this case if you want to run only next task with parameters - you need to define parameters
# like that [:arg1, :arg2, ...] so then in ENV they would be available like ENV['arg1']
# then in cmd: rake task_6639_ssh_exit_code['TEST/vboxnode']
task :task_6639_ssh_exit_code, [:pathToConfigToVBOXNode, :pathToConfigToMDBCINode, :pathToConfigToMDBCIFolder, :pathToConfigToMDBCINode] do |t, args| RakeTaskManager.new(t).run_parametrized(args) end
task :task_generator do |t| RakeTaskManager.new(t).run end
task :task_6640_sudo_exit_code, [:pathToConfigToVBOXNode] do |t, args| RakeTaskManager.new(t).run_parametrized(args) end
task :task_6641_setup_exit_code, [:pathToTestBoxes, :testBoxName] do |t, args| RakeTaskManager.new(t).run_parametrized(args) end
task :task_6642_show_keyfile_exit_code, [:pathToConfigToVBOXNode, :pathToConfigToMDBCINode, :pathToConfigToMDBCIFolder, :pathToConfigToMDBCINode] do |t, args| RakeTaskManager.new(t).run_parametrized(args) end
task :task_6643_show_network_exit_code, [:pathToConfigToVBOXNode, :pathToConfigToMDBCINode, :pathToConfigToMDBCIFolder, :pathToConfigToMDBCINode] do |t, args| RakeTaskManager.new(t).run_parametrized(args) end
task :task_6644_show_private_ip_exit_code, [:pathToConfigToVBOXNode, :pathToConfigToMDBCINode, :pathToConfigToMDBCIFolder, :pathToConfigToMDBCINode] do |t, args| RakeTaskManager.new(t).run_parametrized(args) end
task :task_6645_public_keys_exit_code, [:pathToConfigToVBOXNode, :pathToConfigToMDBCINode, :pathToConfigToMDBCIFolder, :pathToConfigToMDBCINode] do |t, args| RakeTaskManager.new(t).run_parametrized(args) end
task :task_shell_command_testing_example do |t| RakeTaskManager.new(t).run end
task :task_6819_show_box_info do |t| RakeTaskManager.new(t).run end
task :task_6782_show_commands_exit_code do |t| RakeTaskManager.new(t).run end
task :task_6646_setup_repo_exit_code, [:pathToConfigToVBOXNode, :pathToConfigToMDBCINode, :pathToConfigToMDBCIFolder, :pathToConfigToMDBCINode] do |t, args| RakeTaskManager.new(t).run_parametrized(args) end
task :task_6647_install_product_exit_code, [:pathToConfigToVBOXNode, :pathToConfigToMDBCINode, :pathToConfigToMDBCIFolder, :pathToConfigToMDBCINode] do |t, args| RakeTaskManager.new(t).run_parametrized(args) end
task :task_6648_generate_exit_code, [:pathToVBOXConfigFile, :pathToMDBCIConfigFile, :pathToDestination] do |t, args| RakeTaskManager.new(t).run_parametrized(args) end
task :task_6755_show_platform_versions do |t| RakeTaskManager.new(t).run end

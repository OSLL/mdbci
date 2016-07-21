require 'rspec'
require_relative '../spec_helper'
require_relative '../../core/helper'

TEMPLATE_LIBVIRT = "spec/configs/template/libvirt_lite.json"
MACHINE_LIBVIRT = "7190_test_libvirt_machine"
NEW_PATH_LIBVIRT = "7190_new_test_libvirt_machine"
TEMPLATE_DOCKER = "spec/configs/template/docker_lite.json"
MACHINE_DOCKER = "7190_test_docker_machine"
NEW_PATH_DOCKER = "7190_new_test_docker_machine"


describe 'test_spec' do

  before :all do
    setUp(TEMPLATE_LIBVIRT, MACHINE_LIBVIRT)
    setUp(TEMPLATE_DOCKER, MACHINE_DOCKER)
  end

  executeShellCommandsAndTestExitCode ([
    {'shell_command'=>"./mdbci clone #{MACHINE_LIBVIRT} #{NEW_PATH_LIBVIRT}", 'expectation'=>0},
    {'shell_command'=>"./mdbci clone #{MACHINE_DOCKER} #{NEW_PATH_DOCKER}", 'expectation'=>0},
    {'shell_command'=>"./mdbci clone #{MACHINE_LIBVIRT} ", 'expectation'=>1},
    {'shell_command'=>"./mdbci clone #{MACHINE_LIBVIRT} #{MACHINE_DOCKER}", 'expectation'=>1}
  ])

  after :all do
    tearDown(MACHINE_LIBVIRT)
    tearDown(MACHINE_DOCKER)
  end

end


def setUp(template, name_machine)
  puts "generate #{name_machine}"
  execute_bash("./mdbci --template #{template} generate #{name_machine}")
  puts "up #{name_machine}"
  out = execute_bash("./mdbci up #{name_machine} ")
  puts "cd #{name_machine}"
  execute_bash("cd #{name_machine}")
  execute_bash("vagrant halt")
  execute_bash("cd -")
  puts "shut down the running machine #{name_machine}"
end


def tearDown(name_machine)
  puts Dir.pwd
  execute_bash("cd #{name_machine}")
  execute_bash("vagrant destroy -f")
  execute_bash("cd -")
  execute_bash("rm -r #{name_machine}")
  puts "destroy the machine #{name_machine}"
end

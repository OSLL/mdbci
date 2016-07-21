require 'rspec'
require_relative '../spec_helper'
require_relative '../../core/helper'

TEMPLATE_LIBVIRT = "spec/configs/template/libvirt_lite.json"
MACHINE_LIBVIRT = "7190_test_libvirt_machine"
NEW_PATH_LIBVIRT = "7190_new_test_libvirt_machine"


describe 'test_spec' do

  before :all do
    setUp(TEMPLATE_LIBVIRT, MACHINE_LIBVIRT)
  end

  executeShellCommandsAndTestExitCode ([
    {'shell_command'=>"./mdbci clone #{MACHINE_LIBVIRT} #{NEW_PATH_LIBVIRT}", 'expectation'=>1},
  ])

  after :all do
    tearDown(MACHINE_LIBVIRT)
  end

end


def setUp(template, name_machine)
  execute_bash("./mdbci --template #{template} generate #{name_machine}")
  execute_bash("./mdbci up #{name_machine}")
  execute_bash("cd #{name_machine}")
  execute_bash("vagrant halt")
  execute_bash("cd -")
  execute_bash("rm #{MACHINE_LIBVIRT}/provider")
end


def tearDown(name_machine)
  execute_bash("cd #{name_machine}")
  execute_bash("vagrant destroy -f")
  puts "destroy the machine #{name_machine}"
  execute_bash("cd -")
  execute_bash("rm -r #{name_machine}")
end

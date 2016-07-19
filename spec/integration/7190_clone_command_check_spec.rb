require 'rspec'
require_relative '../spec_helper'

TEMPLATE_LIBVIRT = "spec/configs/template/libvirt_lite.json"
MACHINE_LIBVIRT = "7190_test_libvirt_machine"
TEMPLATE_DOCKER = "../spec/configs/template/docker.json"
MACHINE_DOCKER = "7190_test_docker_machine"
NEW_PATH_LIBVIRT = "7190_new_test_libvirt_machine"


describe 'test_spec' do

  before :all do
    puts Dir.pwd
    puts Dir.entries('spec/configs/template')
    `"./mdbci --template #{TEMPLATE_LIBVIRT} generate #{MACHINE_LIBVIRT}"`
    `"ls"`
    `"./mdbci up #{MACHINE_LIBVIRT}"`
    `"cd #{MACHINE_LIBVIRT}"`
    `vagrant halt`
    `cd -`
  end

  executeShellCommandsAndTestExitCode ([
    {'shell_command'=>"./mdbci clone #{MACHINE_LIBVIRT} #{NEW_PATH_LIBVIRT}", 'expectation'=>0}
  ])

#  after :all do
#      `vagrant destroy -f`
#  end

end

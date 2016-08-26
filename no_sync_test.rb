require_relative 'core/helper'

DOCKER='docker'
LIBVIRT='libvirt'

SLEEP_TIME=5

$times=Hash.new

def with_timer(id)
  start = Time.now.to_i
  yield
  $times[id] = Time.now.to_i - start
  sleep SLEEP_TIME
end

def in_dir(dir)
  if Dir.exist? dir
    root = Dir.pwd
    Dir.chdir dir
    yield
    Dir.chdir root
  end
end

require 'rspec'
require_relative 'spec/spec_helper'
require_relative 'core/out'
require_relative 'core/exception_handler'
require_relative 'core/boxes_manager'
require_relative 'core/session'

$out = Out.new
$session = Session.new
$session.isSilent = false
$session.mdbciDir = Dir.pwd
$exception_handler = ExceptionHandler.new
boxesPath = './BOXES'
$session.boxes = BoxesManager.new boxesPath
reposPath = './repo.d'
$session.repos = RepoManager.new reposPath

execute_bash('./mdbci --template spec/parametrized_tests_templates/libvirt.json generate libvirt')

in_dir(LIBVIRT) { execute_bash('vagrant destroy -f') }
in_dir("#{LIBVIRT}_1") { execute_bash('vagrant destroy -f') }
FileUtils.rm_rf "#{LIBVIRT}_1"

with_timer(LIBVIRT) {
  $session.up(LIBVIRT)
}

with_timer("#{LIBVIRT}_1") {
  $session.clone(LIBVIRT, "#{LIBVIRT}_1")
}

puts $times
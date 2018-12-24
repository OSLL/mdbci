require 'rspec'
require_relative '../spec_helper'
require_relative '../../core/out'
require_relative '../../core/exception_handler'
require_relative '../../core/session'
require_relative '../../core/helper'

CLONED_DOCKER_CONFIG_NAME = 'qwerty_123_docker'
CLONED_LIBVIRT_CONFIG_NAME = 'qwerty_123_libvirt'

describe 'Session' do

  before :all do
    $mdbci_exec_dir = File.absolute_path('.')
    $out = Out.new
    $session = Session.new
    $session.isSilent = true
    $session.mdbciDir = Dir.pwd
    $exception_handler = ExceptionHandler.new
    boxesPath = './BOXES'
    $session.boxes = BoxesManager.new boxesPath
    reposPath = './config/repo.d'
    $session.repos = RepoManager.new reposPath
  end

  after :all do
    Dir.glob('BOXES/fake_docker_boxes_*') { |fake_boxes| FileUtils.rm_rf fake_boxes}
    destroy_config(CLONED_DOCKER_CONFIG_NAME)
    FileUtils.rm_rf "#{get_template_directory(ENV['mdbci_param_conf_docker'])}/#{CLONED_DOCKER_CONFIG_NAME}.json"
    images = `docker images | grep #{CLONED_DOCKER_CONFIG_NAME} | awk '{print $1}'`
    images.each_line {|line| system("docker rmi #{line}") }
    destroy_config(CLONED_LIBVIRT_CONFIG_NAME)
    FileUtils.rm_rf "#{get_template_directory(ENV['mdbci_param_conf_libvirt'])}/#{CLONED_LIBVIRT_CONFIG_NAME}.json"
  end

  it '#clone should exit with zero code for libvirt provider' do
    $session.clone_config(ENV['mdbci_param_conf_libvirt'], CLONED_LIBVIRT_CONFIG_NAME).should(eql(0))
  end


  it '#clone should exit with zero code for docker provider' do
    $session.clone_config(ENV['mdbci_param_conf_docker'], CLONED_DOCKER_CONFIG_NAME).should(eql(0))
  end


  it '#clone should exit with non-zero code for another provider ' do
    lambda{$session.clone_config(ENV['mdbci_param_conf_ppc'].to_s, 'NEVER_HAPPENS')}.should raise_error('mdbci: provider does not support cloning')
  end

end

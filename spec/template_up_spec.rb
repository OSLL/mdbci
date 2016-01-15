require 'rspec'
require 'spec_helper'

require_relative '../core/session'
require_relative '../core/network'
require_relative '../core/node'
require_relative '../core/boxes_manager'
require_relative '../core/out'
require_relative '../core/exception_handler'

RSpec.describe "VBoxTemplateCommandsTests", :order => :defined do
  before(:context) {@up_exit_code = 1}

  before(:each) do

    $session = Session.new
    $session.isSilent = false
    $out = Out.new
    $exception_handler = ExceptionHandler.new

    boxesPath = "./BOXES"
    $session.boxes = BoxesManager.new(boxesPath)

    @pwd = Dir.pwd
    $out.info "PWD: " + @pwd.to_s

    @templateDir = @pwd.to_s+"/"+"template_up_test"
    $out.info "templateDir: " + @templateDir

    $session.mdbciDir = @pwd.to_s
    $out.info "mdbciDir: " + $session.mdbciDir

  end

'''
  it "./mdbci generate and up test" do

    $session = Session.new
    $session.isSilent = false
    $out = Out.new

    $exception_handler = ExceptionHandler.new

    $session.configFile = "confs/rspec_vm_test.json"
    $session.nodesProvider = "virtualbox"
    $session.isOverride = true

    path = "./repo.d"
    $session.repos = RepoManager.new(path)

    boxesPath = "./BOXES"
    $session.boxes = BoxesManager.new(boxesPath)
    #$session.boxes.boxesManager.size().should_not eq(0)
    #$session.boxes.boxesManager.size().should eq(31)

    nodes = JSON.parse(IO.read($session.configFile))
    #nodes.size().should_not eq(0)
    #nodes.size().should eq(7)

    # Generator.generate(path, config, boxes, override, provider)
    path = "template_up_test"
    #Generator.generate(path,nodes,$session.boxes,$session.isOverride,$session.nodesProvider)
    $session.generate(path)

    # up generated template
    @up_exit_code = $session.up(path)
    @up_exit_code.should eq(0)      # success

  end
'''
  it "nodesStatusTest" do

    network = Network.new
    network.loadNodes @pwd.to_s + "/" + "template_up_test"

    $out.info "Nodes: " + network.nodes.to_s
    network.nodes.size().should eq(2)
  end

  #
  # mdbci commands
  #
  it "./mdbci show network test" do

    path = "template_up_test"
    $out.info "up exit code = " + @up_exit_code.to_s
    if @up_exit_code == 1

      $out.info "mdbciDir: " + $session.mdbciDir.to_s
      Network.show path.to_s

    end

  end
'''
  it "./mdbci show keyfile test" do

    path = "template_up_test"
    $out.info "up exit code = " + @up_exit_code.to_s
    if @up_exit_code == 0
      network.loadNodes pwd.to_s
      Network.showKeyFile path.to_s
    end

  end

  it "./mdbci show private_ip test" do

    pwd = Dir.pwd
    network = Network.new

    path = "template_up_test/node0"
    network.loadNodes pwd.to_s
    Network.private_ip path.to_s

  end

  it "./mdbci ssh test" do

    $session = Session.new
    $session.isSilent = false
    $session.command = "whoami"
    $out = Out.new

    path = "template_up_test/node0"
    $session.ssh path.to_s

  end

  it "./mdbci sudo test" do

    $session = Session.new
    $session.isSilent = false
    $session.command = "whoami"
    $out = Out.new

    path = "template_up_test/build"
    $session.sudo(path)
  end

  it "./mdbci public_keys test" do
    # TBD
  end

  it "./mdbci install_repo test" do
    # TBD
  end

  it "./mdbci update_repo test" do
    # TBD
  end
  '''
end
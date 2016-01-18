require 'rspec'
require 'spec_helper'

require_relative '../core/session'
require_relative '../core/network'
require_relative '../core/node'
require_relative '../core/boxes_manager'
require_relative '../core/out'
require_relative '../core/exception_handler'

RSpec.describe "VBoxTemplateCommandsTests", :order => :defined do
  before(:context) { @up_exit_code = 0 }

  before(:each) do

    $session = Session.new
    $session.isSilent = false
    $session.configFile = "confs/rspec_vm_test.json"
    $session.nodesProvider = "virtualbox"
    $session.isOverride = true

    $out = Out.new

    $exception_handler = ExceptionHandler.new

    boxesPath = "./BOXES"
    $session.boxes = BoxesManager.new(boxesPath)

    path = "./repo.d"
    $session.repos = RepoManager.new(path)

    @pwd = Dir.pwd
    $out.info "PWD: " + @pwd.to_s

    @templateDir = @pwd.to_s+"/"+"template_up_test"
    $out.info "templateDir: " + @templateDir.to_s

    $session.mdbciDir = @pwd.to_s
    $out.info "mdbciDir: " + $session.mdbciDir.to_s

  end

  it "./mdbci generate and up test" do

    # Generator.generate(path, config, boxes, override, provider)
    template_path = "template_up_test"
    #Generator.generate(path,nodes,$session.boxes,$session.isOverride,$session.nodesProvider)
    $session.generate template_path.to_s

    # up generated template
    @up_exit_code = $session.up template_path.to_s
    @up_exit_code.should eq(0)      # success

  end

  it "nodesStatusTest" do

    network = Network.new
    network.loadNodes @templateDir.to_s

    $out.info "Nodes: " + network.nodes.to_s
    network.nodes.size().should eq(2)
  end

  #
  # mdbci commands
  #
  it "./mdbci show network test" do

    path = "template_up_test"
    $out.info "up exit code = " + @up_exit_code.to_s
    if @up_exit_code == 0

      Network.show path.to_s

    end

  end

  it "./mdbci show keyfile test" do

    path = "template_up_test/node0"
    if @up_exit_code == 0

      Network.showKeyFile path.to_s

    end

  end

  it "./mdbci show private_ip test" do

    path = "template_up_test/node0"
    if @up_exit_code == 0

      Network.private_ip path.to_s

    end
  end

  it "./mdbci ssh test" do

    $session.command = "whoami"

    path = "template_up_test/node0"
    if @up_exit_code == 0
      $session.ssh path.to_s
    end

  end

  it "./mdbci sudo test" do

    $session.command = "whoami"

    path = "template_up_test/node1"
    if @up_exit_code == 0
      $session.sudo path.to_s
    end

  end
  '''
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

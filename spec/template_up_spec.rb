require 'rspec'
require 'spec_helper'

require_relative '../core/session'
require_relative '../core/network'
require_relative '../core/boxes_manager'
require_relative '../core/out'
require_relative '../core/exception_handler'

describe 'VBoxTemplateCommandsTests' do

  context '.vmTemplateCommands' do

    it "./mdbci generate and up test" do
      #pending # useful for Debugging

      $session = Session.new
      $session.isSilent = false
      $out = Out.new

      $exception_handler = ExceptionHandler.new

      $session.configFile='confs/rspec_vm_test.json'
      $session.nodesProvider = 'virtualbox'
      $session.isOverride = true

      path = './repo.d'
      $session.repos = RepoManager.new(path)

      boxesPath = './BOXES'
      $session.boxes = BoxesManager.new(boxesPath)
      $session.boxes.boxesManager.size().should_not eq(0)
      $session.boxes.boxesManager.size().should eq(31)

      nodes = JSON.parse(IO.read($session.configFile))
      #nodes.size().should_not eq(0)
      #nodes.size().should eq(7)

      # Generator.generate(path, config, boxes, override, provider)
      path = 'template_up_test'
      #Generator.generate(path,nodes,$session.boxes,$session.isOverride,$session.nodesProvider)
      $session.generate(path)

      # up generated template
      #exit_code = $session.up(path)
      #exit_code.should eq(0)      # success
      #exit_code.should_not eq(1)  # error

    end
    #
    # mdbci commands
    #
    it "./mdbci show network test" do

      #$session = Session.new
      #$session.isSilent = false
      #$out = Out.new

      pwd = Dir.pwd
      network = Network.new

      path = 'template_up_test/node0'
      network.loadNodes pwd.to_s
      network.show(path)

    end

    it "./mdbci show keyfile test" do

      pwd = Dir.pwd
      network = Network.new

      path = 'template_up_test/node0'
      network.loadNodes pwd.to_s
      network.showKeyFile(path)

    end

    it "./mdbci show private_ip test" do

      pwd = Dir.pwd
      network = Network.new

      path = 'template_up_test/node0'
      network.loadNodes pwd.to_s
      network.private_ip(path)

    end

    it "./mdbci ssh test" do

      $session = Session.new
      $session.isSilent = false
      $session.command = 'whoami'
      $out = Out.new

      #$network = Network.new

      path = 'template_up_test/node0'
      $session.ssh(path)

    end

    it "./mdbci sudo test" do

      $session = Session.new
      $session.isSilent = false
      $session.command = 'whoami'
      $out = Out.new

      #$network = Network.new

      path = 'template_up_test/build'
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

  end

end
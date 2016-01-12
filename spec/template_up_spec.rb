require 'rspec'
require 'spec_helper'

require_relative '../core/session'
require_relative '../core/boxes_manager'
require_relative '../core/out'
require_relative '../core/exception_handler'

describe 'TemplateUpAutoTest' do

  context '.vmUpTemplate' do

    it "Create template and up it ..." do
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
      $session.boxes.boxesManager.size().should eq(30)

      nodes = JSON.parse(IO.read($session.configFile))
      #nodes.size().should_not eq(0)
      #nodes.size().should eq(7)

      # Generator.generate(path, config, boxes, override, provider)
      path = 'template_up_test'
      #Generator.generate(path,nodes,$session.boxes,$session.isOverride,$session.nodesProvider)
      $session.generate(path)

      # up generated template
      exit_code = $session.up(path)
      exit_code.should eq(0)      # success
      exit_code.should_not eq(1)  # error

    end

  end



end
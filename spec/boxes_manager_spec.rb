require 'rspec'
require 'spec_helper'

require_relative '../core/session'
require_relative '../core/boxes_manager'
require_relative '../core/out'

describe 'BoxesManager' do

  context

  it 'lookup and add boxes' do

    $session = Session.new
    $session.isSilent = false
    $out = Out.new

    path = Dir.pwd
    boxes = BoxesManager.new(path)

    boxes.boxes.size().should_not eq(0)
    boxes.boxes.size().should eq(40)

  end

end
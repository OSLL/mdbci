require 'rspec'
require 'spec_helper'

require_relative '../core/session'
require_relative '../core/boxes_manager'
require_relative '../core/out'

describe 'BoxesManager' do

  it 'lookup and add boxes' do
    $session = Session.new
    $session.isSilent = false
    $out = Out.new

    path = './BOXES'
    boxes = BoxesManager.new(path)

    boxes.boxesManager.size().should_not eq(0)
    boxes.boxesManager.size().should eq(30)
  end

end

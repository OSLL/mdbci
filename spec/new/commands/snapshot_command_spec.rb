# frozen_string_literal: true

describe SnapshotCommand do
  describe '.check_and_get_action' do
    it 'should return known action if correct action name is passed' do
      command = SnapshotCommand.new([SnapshotCommand::ACTION_TAKE], nil, nil)
      expect(command.check_and_get_action).to eq(SnapshotCommand::ACTION_TAKE)
    end

    it 'should raise error if no parameters are passed' do
      command = SnapshotCommand.new([], nil, nil)
      expect { command.check_and_get_action }.to raise_error(RuntimeError)
    end

    it 'should raise error if unknown action is passed' do
      command = SnapshotCommand.new(['unknown'], nil, nil)
      expect { command.check_and_get_action }.to raise_error(RuntimeError)
    end
  end
end

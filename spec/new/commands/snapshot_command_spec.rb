# frozen_string_literal: true

describe SnapshotCommand do
  describe '#check_and_get_action' do
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

  describe '#execute_bash' do
    it 'should disable output to stdout' do
      output = double
      command = SnapshotCommand.new(nil, nil, output)
      command.execute_bash('echo test', true)
    end

    it 'should print output ot stdout' do
      output = double
      command = SnapshotCommand.new(nil, nil, output)
      expect(output).to receive(:info)
      command.execute_bash('echo test', false)
    end

    it 'should not raise error if command was sucessful' do
      command = SnapshotCommand.new(nil, nil, nil)
      expect { command.execute_bash('exit 0', true) }.not_to raise_error
    end

    it 'should reais error if command have failed' do
      command = SnapshotCommand.new(nil, nil, nil)
      expect { command.execute_bash('exit 1', true) }.to raise_error(RuntimeError)
    end

    it 'should return a list of output messages' do
      command = SnapshotCommand.new(nil, nil, nil)
      message = 'testing the function'
      expect(command.execute_bash("echo #{message}", true)).to eq([message])
    end
  end
end

# frozen_string_literal: true

require 'commands/base_command'

describe BaseCommand do
  context '.synopsis' do
    it 'should return string' do
      expect(BaseCommand.synopsis.class).to be(String)
    end
  end

  context '#execute' do
    it 'should raise exception' do
      command = BaseCommand.new(nil, nil, nil)
      expect do
        command.execute
      end.to raise_error(RuntimeError)
    end
  end
end

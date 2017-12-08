# frozen_string_literal: true

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

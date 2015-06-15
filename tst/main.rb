class Main

  def fails
    0
  end

def new
	return 0
end

end


describe Main do

  it 'should run all tests' do
    main = Main.new
    expect(main.fails).to eq(1)
  end

end

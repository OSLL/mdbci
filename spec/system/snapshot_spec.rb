describe 'snaphot command', :system do
  context 'revert subcommand' do
    context 'when trying to revert non-created configuration' do
      it 'should return error code' do
        run_mdbci('generate ')
      end
    end
  end
end

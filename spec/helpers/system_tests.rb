# frozen_string_literal: true

require 'open3'

# Module allows to easily write system tests
module SystemTests
  # Method executes the passed commands on the shell
  # and checks that status code matches with the expectation
  #
  # @param shall_command_with_expectations [Array] of Hashes having
  # shell_command and exit_code parameters defined.
  # Hash example: { shell_command: 'echo *', exit_code: 0 }
  def execute_shell_commands_and_test_exit_code(shell_commands_with_expectations)
    context 'shell command' do
      shell_commands_with_expectations.each do |shell_command_with_expectation|
        shell_command = shell_command_with_expectation[:shell_command]
        expectation = shell_command_with_expectation[:exit_code]
        it shell_command do
          _, status = Open3.capture2e(shell_command)
          expect(status.exitstatus).to eq(expectation)
        end
      end
    end
  end
end

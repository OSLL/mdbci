require 'open3'

# Module provides methods to test the execution of shell-commands
module ShellHelper
  # Internal module that provides the functionality
  module ClassMethods
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
            _, _, _, wait_thr = Open3.popen3(shell_command)
            wait_thr.value.exitstatus.should(eql(expectation))
          end
        end
      end
    end
  end

  def self.included(base)
    base.extend(ClassMethods)
  end
end

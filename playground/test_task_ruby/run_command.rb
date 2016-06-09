require 'optparse'
require 'shellwords'


ARG_COMMAND = '--c [ARG]'

OptionParser.new do |opts|
    opts.banner = "Usage: run_command.rb -c <<command>>"
    opts.on(ARG_COMMAND, "Specify the filename") do |v|
        COMMAND = v
    end
end.parse!

begin
    escaped_command = Shellwords.escape(COMMAND) 
    res = system "bash -c #{escaped_command}"
    puts "Exit code"
    puts $?.exitstatus
    if !res
        raise "Error while executing command " + COMMAND
    end
end

require "open3"

ERROS_DIR = "ERRORS"

Dir.mkdir ERROS_DIR

(1..5).each do |i|
	error = ''
	status = Open3.popen3(cmd_up) do |stdin, stdout, stderr, wthr|
		stdin.close
        stdout.each_line { |line| puts line }
        stdout.close
        stderr.each_line do |line|
        	error = "#{error}\n#{line}"
        	puts line
        end
        stderr.close
        wthr.value
	end
	unless status.success?
		File.open("#{i}", "w") do |f|
			f.write error
		end
	end
end

require 'rubygems'
require 'json'
require 'optparse'

ARG_FILENAME = '--filename [ARG]'

OptionParser.new do |opts|
    opts.banner = "Usage: validate.rb --filename <<file name>>"
    FILE_NAME = '11111'
    opts.on(ARG_FILENAME, "Specify the filename") do |v|
        FILE_NAME = v
    end
end.parse!

KEY_STR = 'str'
KEY_ARR = 'arr'

config = IO.read(FILE_NAME)
begin
    res = JSON.parse(config)
rescue 
    puts "ERROR WHILE PARSING FILE"
    exit
end

begin
    if res[KEY_STR].class != String
        raise "Value type in str key is not valid ERROR"
    end
end

begin
    if res[KEY_ARR].class != Array
        raise "Value type in arr key is not valid ERROR"
    else
        if res[KEY_ARR].size != 5
            raise "Value in arr key doesn't have valid size ERROR"
        end
    end
end

puts "OK"

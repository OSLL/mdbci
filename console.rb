# frozen_string_literal: true

require 'pry'
current_path = File.expand_path('../core', __FILE__)
source_files = Dir.glob("#{current_path}/**/*.rb")
source_files.each do |file|
  require file
end
# rubocop:disable Lint/Debugger
binding.pry
# rubocop:enable Lint/Debugger

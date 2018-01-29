# frozen_string_literal: true

# Command provides a documentation to the user on how to use the mdbci tool.
class HelpCommand < BaseCommand
  def self.synopsis
    'Show information about MDBCI tool and it commands'
  end

  HELP_TEMPLATE_FILE = File.expand_path('../../../docs/help.erb', __FILE__)

  # Show overview about all the commands that are available
  def show_overview
    File.open(HELP_TEMPLATE_FILE) do |file|
      @ui.out(file.read)
    end
  end

  def execute
    show_overview
    SUCCESS_RESULT
  end
end

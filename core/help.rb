require_relative '../core/out'

DOCS_HELP_PATH = 'docs/help.md'


class Help
  def Help.display
    
    $out.out `cat #{DOCS_HELP_PATH}`
 
  end

end

class Help

def Help.display
  puts <<-EOF
mdbci [option] <up>

-h, --help:
  Shows this help screen

-c, --config [config file]
  Uses [config file] for running instance. by default 'config.mdbci' will be used.

-p, --platforms
  Show list of supported platforms
  EOF

end

end

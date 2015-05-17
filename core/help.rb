class Help

def Help.display
  puts <<-EOF
mdbci [option] <make | prepare | run>

-h, --help:
  Shows this help screen

-t, --template [config file]:
  Uses [config file] for running instance. By default 'instance.json' will be used as config template.

-p, --platforms:
  Show list of supported platforms

-w, --override

Configname is a directory what will be created for new vagrant configuration. Process will fail if directory already exists. Use key -w to override configuration.

  EOF

end

end

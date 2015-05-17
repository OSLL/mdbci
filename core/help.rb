class Help

def Help.display
  puts <<-EOF
mdbci [option] <show | setup | generate>

-h, --help:
  Shows this help screen

-t, --template [config file]:
  Uses [config file] for running instance. By default 'instance.json' will be used as config template.

-p, --platforms:
  Show list of supported platforms

-w, --override
  Override previous configuration

  EOF

end

end

require_relative '../core/out'


class Help

def Help.display
  $out.out <<-EOF
mdbci [option] <show | setup | generate>

-h, --help:
  Shows this help screen

-t, --template [config file]:
  Uses [config file] for running instance. By default 'instance.json' will be used as config template.

-b, --boxes [boxes file]:
  Uses [boxes file] for existing boxes. By default 'boxes.json'  will be used as boxes file.

-w, --override
  Override previous configuration

-s, --silent
  Keep silence, output only requested info or nothing if not available

COMMANDS:
  show [boxes, platforms, versions, network [config | config/node] ]
  generate
  setup [boxes]

  EOF

end

end

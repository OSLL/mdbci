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

-c, --command
  Set command to run for sudo or ssh clause

-s, --silent
  Keep silence, output only requested info or nothing if not available

-r, --repo-dir
  Change default place for repo.d

-a --attempts
  Deploy configuration or node

-p, --product
  Product name for install and update repo commands

COMMANDS:
  show [boxes, platforms, versions, network, repos [config | config/node], keyfile config/node ]
  generate
  setup [boxes]
  sudo --command 'command arguments' config/node
  ssh --command 'command arguments' config/node
  up [--attempts 'attempts arguments'] config | config/node
  install_repo --product <product_name> config/node
  update_repo --product <profuct_name> config/node

EXAMPLES:
  mdbci sudo --command "tail /var/log/anaconda.syslog" T/node0 --silent
  mdbci ssh --command "cat script.sh" T/node1
  mdbci --repo-dir /home/testbed/config/repos show repos
  mdbci up --attempts 4 T/node0
  mdbci install_repo --product maxscale T/node0
  mdbci update_repo --product maxscale T/node0
  EOF

end

end

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

-n, --box-name [box name]:
  Use [box name] for existing box names.

-f, --field [box config field]:
  Use [box config field] for existing box config field.

-w, --override
  Override previous configuration

-c, --command
  Set command to run for sudo or ssh clause

-s, --silent
  Keep silence, output only requested info or nothing if not available

-r, --repo-dir
  Change default place for repo.d

-a, --attempts
  Deploy configuration or node

-p, --product
  Product name for setup repo and install product commands

-v, --product-version
  Product version for setup repo and install product commands

-k, --key
  Keyfile to the node for public_keys command

-o, --platform
  Platform name for the show boxes command

-i, --platform-version
  Platform version for the show boxes command. Must be used together with --platform option!

COMMANDS:
  show [platforms, versions, network, repos [config | config/node], keyfile config/node ]
  generate
  setup [boxes]
  show boxes --platform 'box platform' --platform-version 'box platform version'
  sudo --command 'command arguments' config/node
  ssh --command 'command arguments' config/node
  up [--attempts 'attempts arguments'] config | config/node
  setup_repo --product <product_name> config/node
  install_product --product <product_name> config/node
  public_keys --key keyfile.pem config/node


EXAMPLES:
  mdbci show versions --platform ubuntu
  mdbci show boxes --platform centos
  mdbci show boxes --platform ubuntu --platform-version trusty
  mdbci sudo --command "tail /var/log/anaconda.syslog" T/node0 --silent
  mdbci ssh --command "cat script.sh" T/node1
  mdbci --repo-dir /home/testbed/config/repos show repos
  mdbci up --attempts 4 T/node0
  mdbci setup_repo --product maxscale T/node0
  mdbci setup_repo --product mariadb --product-version 10.0 T/node0
  mdbci install_product --product maxscale T/node0
  mdbci public_keys --key keyfile.pem T/node0
  EOF

end

end

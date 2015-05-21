MariaDB Cookbook
=====================

The MariaDB Cookbook is a library cookbook that provides resource primitives
(LWRPs) for use in recipes. It is designed to be a reference example for
creating highly reusable cross-platform cookbooks.

Scope
-----
This cookbook is concerned with the "MariaDB Enterprise Server",
particularly those shipped with F/OSS Unix and Linux distributions.

Requirements
------------
- Chef 11 or higher
- Ruby 1.9 or higher (preferably from the Chef full-stack installer)
- Network accessible package repositories
- 'recipe[selinux::disabled]' on RHEL platforms

Platform Support
----------------
The following platforms have been tested with Test Kitchen:

```
|----------------+-----+------|
|                | 5.5 | 10.0 |
|----------------+-----+------|
| debian-6       |     | X    |
|----------------+-----+------|
| debian-7       |     | X    |
|----------------+-----+------|
| ubuntu-10.04   |     | X    |
|----------------+-----+------|
| ubuntu-12.04   |     | X    |
|----------------+-----+------|
| ubuntu-14.04   |     | X    |
|----------------+-----+------|
| centos-5       |   X | X    |
|----------------+-----+------|
| centos-6       |     | X    |
|----------------+-----+------|
| centos-7       |     | X    |
|----------------+-----+------|
| suse-13        |     |      |
|----------------+-----+------|
| sles-11        |     |      |
|----------------+-----+------|
| sles-12        |     |      |
|----------------+-----+------|
| rhel-5         |     |      |
|----------------+-----+------|
| rhel-6         |     |      |
|----------------+-----+------|
| rhel-7         |     |      |
|----------------+-----+------|
```

Cookbook Dependencies
------------

Usage
-----
Place a dependency on the MariaDB cookbook in your cookbook's metadata.rb
```ruby
depends 'mariadb', '~> 0'
```

Then, in a recipe:

```ruby
mysql_service 'foo' do
  port '3306'
  version '5.5'
  initial_root_password 'change me'
  action [:create, :start]
end
```

The service name on the OS is `mysql-foo`. You can manually start and
stop it with `service mysql-foo start` and `service mysql-foo stop`.

The configuration file is at `/etc/mysql-foo/my.cnf`. It contains the
minimum options to get the service running. It looks like this.

```
# Chef generated my.cnf for instance mysql-default

[client]
default-character-set          = utf8
port                           = 3306
socket                         = /var/run/mysql-foo/mysqld.sock

[mysql]
default-character-set          = utf8

[mysqld]
user                           = mysql
pid-file                       = /var/run/mysql-foo/mysqld.pid
socket                         = /var/run/mysql-foo/mysqld.sock
port                           = 3306
datadir                        = /var/lib/mysql-foo
tmpdir                         = /tmp
log-error                      = /var/log/mysql-foo/error.log
!includedir /etc/mysql-foo/conf.d

[mysqld_safe]
socket                         = /var/run/mysql-foo/mysqld.sock
```

You can put extra configuration into the conf.d directory by using the
`mysql_config` resource, like this:

```ruby
mysql_service 'foo' do
  port '3306'
  version '5.5'
  initial_root_password 'change me'
  action [:create, :start]
end

mysql_config 'foo' do
  source 'my_extra_settings.erb'
  notifies :restart, 'mysql_service[foo]'
  action :create
end
```

You are responsible for providing `my_extra_settings.erb` in your own
cookbook's templates folder.

Connecting with the mysql CLI command
-------------------------------------
Logging into the machine and typing `mysql` with no extra arguments
will fail. You need to explicitly connect over the socket with `mysql
-S /var/run/mysql-foo/mysqld.sock`, or over the network with `mysql -h
127.0.0.1`

Upgrading from older version of the mysql cookbook
--------------------------------------------------
- It is strongly recommended that you rebuild the machine from
  scratch. This is easy if you have your `data_dir` on a dedicated
  mount point. If you *must* upgrade in-place, follow the instructions
  below.

- The 6.x series supports multiple service instances on a single
  machine. It dynamically names the support directories and service
  names. `/etc/mysql becomes /etc/mysql-instance_name`. Other support
  directories in `/var` `/run` etc work the same way. Make sure to
  specify the `data_dir` property on the `mysql_service` resource to
  point to the old `/var/lib/mysql` directory.

Resources Overview
------------------
### mysql_service

The `mysql_service` resource manages the basic plumbing needed to get a
MySQL server instance running with minimal configuration.

The `:create` action handles package installation, support
directories, socket files, and other operating system level concerns.
The internal configuration file contains just enough to get the
service up and running, then loads extra configuration from a conf.d
directory. Further configurations are managed with the `mysql_config` resource.

- If the `data_dir` is empty, a database will be initialized, and a
root user will be set up with `initial_root_password`. If this
directory already contains database files, no action will be taken.

The `:start` action starts the service on the machine using the
appropriate provider for the platform. The `:start` action should be
omitted when used in recipes designed to build containers.

#### Example
```ruby
mysql_service 'default' do
  version '5.7'
  bind_address '0.0.0.0'
  port '3306'  
  data_dir '/data'
  initial_root_password 'Ch4ng3me'
  action [:create, :start]
end
```

Please note that when using `notifies` or `subscribes`, the resource
to reference is `mysql_service[name]`, not `service[mysql]`.

#### Parameters

- `charset` - specifies the default character set. Defaults to `utf8`.

- `data_dir` - determines where the actual data files are kept
on the machine. This is useful when mounting external storage. When
omitted, it will default to the platform's native location.

- `initial_root_password` - allows the user to specify the initial
  root password for mysql when initializing new databases.
  This can be set explicitly in a recipe, driven from a node
  attribute, or from data_bags. When omitted, it defaults to
  `ilikerandompasswords`. Please be sure to change it.

- `instance` - A string to identify the MySQL service. By convention,
  to allow for multiple instances of the `mysql_service`, directories
  and files on disk are named `mysql-<instance_name>`. Defaults to the
  resource name.

- `bind_address` - determines the listen IP address for the mysqld service. When
  omitted, it will be determined by MySQL. If the address is "regular" IPv4/IPv6
  address (e.g 127.0.0.1 or ::1), the server accepts TCP/IP connections only for
  that particular address. If the address is "0.0.0.0" (IPv4) or "::" (IPv6), the
  server accepts TCP/IP connections on all IPv4 or IPv6 interfaces.

- `port` - determines the listen port for the mysqld service. When
  omitted, it will default to '3306'.

- `run_group` - The name of the system group the `mysql_service`
  should run as. Defaults to 'mysql'.

- `run_user` - The name of the system user the `mysql_service` should
  run as. Defaults to 'mysql'.

- `socket` - determines where to write the socket file for the
  `mysql_service` instance. Useful when configuring clients on the
  same machine to talk over socket and skip the networking stack.
  Defaults to a calculated value based on platform and instance name.

#### Actions

- `:create` - Configures everything but the underlying operating system service.
- `:delete` - Removes everything but the package and data_dir.
- `:start` - Starts the underlying operating system service
- `:stop`-  Stops the underlying operating system service
- `:restart` - Restarts the underlying operating system service
- `:reload` - Reloads the underlying operating system service

#### Providers
Chef selects the appropriate provider based on platform and version,
but you can specify one if your platform support it.

```ruby
mysql_service[instance-1] do
  port '1234'
  data_dir '/mnt/lottadisk'
  provider Chef::Provider::MysqlService::Sysvinit
  action [:create, :start]
end
```

- `Chef::Provider::MysqlService` - Configures everything needed t run
a MySQL service except the platform service facility. This provider
should never be used directly. The `:start`, `:stop`, `:restart`, and
`:reload` actions are stubs meant to be overridden by the providers
below.

- `Chef::Provider::MysqlService::Systemd` - Starts a `mysql_service`
using SystemD. Manages the unit file and activation state

- `Chef::Provider::MysqlService::Sysvinit` - Starts a `mysql_service`
using SysVinit. Manages the init script and status.

- `Chef::Provider::MysqlService::Upstart` - Starts a `mysql_service`
using Upstart. Manages job definitions and status.

Advanced Usage Examples
-----------------------
There are a number of configuration scenarios supported by the use of
resource primitives in recipes. For example, you might want to run
multiple MySQL services, as different users, and mount block devices
that contain pre-existing databases.

### Multiple Instances as Different Users

```ruby
# instance-1
user 'alice' do
  action :create
end

directory '/mnt/data/mysql/instance-1' do
  owner 'alice'
  action :create
end

mount '/mnt/data/mysql/instance-1' do
  device '/dev/sdb1'
  fstype 'ext4'
  action [:mount, :enable]
end

mysql_service 'instance-1' do
  port '3307'
  run_user 'alice'
  data_dir '/mnt/data/mysql/instance-1'
  action [:create, :start]
end

mysql_config 'site config for instance-1' do
  instance 'instance-1'
  source 'instance-1.cnf.erb'
  notifies :restart, 'mysql_service[instance-1]'
end

# instance-2
user 'bob' do
  action :create
end

directory '/mnt/data/mysql/instance-2' do
  owner 'bob'
  action :create
end

mount '/mnt/data/mysql/instance-2' do
  device '/dev/sdc1'
  fstype 'ext3'
  action [:mount, :enable]
end

mysql_service 'instance-2' do
  port '3308'
  run_user 'bob'
  data_dir '/mnt/data/mysql/instance-2'
  action [:create, :start]
end

mysql_config 'site config for instance-2' do
  instance 'instance-2'
  source 'instance-2.cnf.erb'
  notifies :restart, 'mysql_service[instance-2]'
end
```
Warnings
--------

License & Authors
-----------------
- Author:: Joshua Timberman (<joshua@chef.io>)
- Author:: AJ Christensen (<aj@chef.io>)
- Author:: Seth Chisamore (<schisamo@chef.io>)
- Author:: Brian Bianco (<brian.bianco@gmail.com>)
- Author:: Jesse Howarth (<him@jessehowarth.com>)
- Author:: Andrew Crump (<andrew@kotirisoftware.com>)
- Author:: Christoph Hartmann (<chris@lollyrock.com>)
- Author:: Sean OMeara (<sean@chef.io>)

```text
Copyright:: 2009-2014 Chef Software, Inc

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```

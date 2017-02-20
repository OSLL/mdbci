#!/bin/bash

set -x

user="$1"
ip="$2"
key_path="$3"
run_command_ret_val=0
run_command() {
		ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i "$key_path" "$user"@"$ip" "$1"
		run_command_ret_val=$?
}
run_command 'sudo apt-get update -y'
run_command 'sudo yum -y check-update'
run_command 'sudo zypper --non-interactive ref'
run_command "git --version"
if [[ "0" -ne "$run_command_ret_val" ]]; then
		run_command 'sudo apt-get install git -y'
		run_command 'sudo yum -y install git'
		#run_command 'sudo zypper --non-interactive install git'
fi
run_command 'git clone https://github.com/akopytov/sysbench.git sysbench'
run_command 'cd sysbench && git checkout 0.5'
run_command 'cd sysbench && ./autogen.sh'
if [[ "0" -ne "$run_command_ret_val" ]]; then
		run_command 'sudo apt-get install  build-essential libtool automake autoconf libmariadbclient-dev -y'
		run_command 'sudo apt-get install libtool automake autoconf libmariadbclient-dev -y'
		run_command 'sudo yum -y groupinstall "Development Tools"'
		run_command 'sudo yum -y install openssl-devel openssl-static mariadb-devel'
		#run_command 'sudo zypper --non-interactive install --type pattern devel_basis'
		#run_command 'sudo zypper --non-interactive install libtool automake autoconf libmariadbclient-dev'
fi
run_command 'cd sysbench && ./autogen.sh'
run_command 'mysql -V'
if [[ "0" -ne "$run_command_ret_val" ]]; then
		echo 'MariaDB or MySQL is not installed'
		exit 1
fi
run_command 'cd sysbench && ./configure'
run_command 'cd sysbench && make'
run_command 'cd sysbench && sudo make install'

set +x

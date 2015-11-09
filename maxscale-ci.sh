#!/bin/bash

# $1 - ci target name
# $2 - destanation

dest=$2
ci=$1

if [ -z $ci_url ]; then
	export ci_url="http://maxscale-jenkins.mariadb.com/ci-repository/"
fi

~/mdbci-repository-config/maxscale.sh $ci_url/$ci/mariadb-maxscale/ $dest

#!/bin/bash

# $1 - ci target name
# $2 - destanation

dest=$2
ci=$1

if [ -z $ci_url ]; then
	export ci_url="http://maxscale-jenkins.mariadb.com/ci-repository/"
fi

#if [ -z $3 ]; then
#	~/mdbci/repository-config/maxscale.sh $ci_url/$ci $dest
#else
	~/mdbci/repository-config/maxscale.sh $ci_url/$ci/$3/ $dest
#fi

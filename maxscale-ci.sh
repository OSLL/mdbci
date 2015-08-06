#!/bin/bash

# $1 - ci target name
# $2 - destanation

dest=$2
ci=$1

./maxscale.sh http://maxscale-jenkins.mariadb.com/ci-repository/$ci/mariadb-maxscale/ $dest

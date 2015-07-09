#!/bin/bash

# $1 - ci target name
# $2 - destanation

dest=$2
ci=$1

./maxscale http://maxscale-jenkins.mariadb.com/repository/$ci/mariadb-maxscale/ $dest

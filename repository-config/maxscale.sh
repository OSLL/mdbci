#!/bin/bash

# $2 - destanation
# $1 - repo path

dest=$2
repo=$1

rm -rf $dest/maxscale
mkdir -p $dest/maxscale

~/mdbci-repository-config/generate_platform_version.sh maxscale "$dest/maxscale-templates"

c_dir=`pwd`

cd $dest/maxscale-templates
list=`ls -1 *.json`
echo $list
cd $c_dir

for f in $list
do
    sed "s|###repo_prefix###|$repo|g" $dest/maxscale-templates/$f  > $dest/maxscale/$f
done

rm -rf $dest/maxscale-templates

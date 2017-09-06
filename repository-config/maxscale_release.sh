#!/bin/bash

# $2 - destanation
# $1 - repo path

dest=$2
repo=$1

c_dir=`pwd`

rm -rf $dest/maxscale-release
mkdir -p $dest/maxscale-release

rm -rf $c_dir/$dest/maxscale-release-templates
mkdir -p $c_dir/$dest/maxscale-release-templates


~/mdbci/repository-config/generate_platform_version.sh maxscale_release "$dest/maxscale-release-templates"



cd $c_dir/$dest/maxscale-release-templates
list=`ls -1 *.json`
echo $list
cd $c_dir

rm -rf $dest/maxscale-release-templates-versions
mkdir -p $dest/maxscale-release-templates-versions

for f in $list
do
    sed "s|###repo_prefix###|$repo|g" $c_dir/$dest/maxscale-release-templates/$f  > $dest/maxscale-release-templates-versions/$f
done

rm -rf $c_dir/$dest/maxscale-release-templates

cd $dest/maxscale-release-templates-versions
list=`ls -1 *.json`
echo $list
cd $c_dir

vers=`cat ~/mdbci/repository-config/maxscale_release/maxscale.version`

for f in $list
do
    for ver in $vers
    do
	echo $f $ver
        sed "s|###version###|$ver|g" $dest/maxscale-release-templates-versions/$f  > $dest/maxscale-release/${ver}_${f}
    done
done

rm -rf $dest/maxscale-release-templates-versions

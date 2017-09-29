#!/bin/bash

# $1 - url to release downloads
# $2 - destanation
# $3 - repo path

downloads_url=$1
dest=$2
repo=$3

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
    sed "s|###repo_prefix###|$downloads_url|g" $c_dir/$dest/maxscale-release-templates/$f  > $dest/maxscale-release-templates-versions/$f
done

rm -rf $c_dir/$dest/maxscale-release-templates

cd $dest/maxscale-release-templates-versions
list=`ls -1 *.json`
echo $list
cd $c_dir

vers=$(./get_release_versions.sh $repo $downloads_url)

for f in $list
do
    for ver in ${vers[@]}
    do
	echo $f $ver
        sed "s|###version###|$ver|g" $dest/maxscale-release-templates-versions/$f  > $dest/maxscale-release/${ver}_${f}
    done
done

rm -rf $dest/maxscale-release-templates-versions

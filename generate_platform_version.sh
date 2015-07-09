#!/bin/bash

# $1 - work dir
# $2 - dest

work_dir=$1
dest=$2

c_dir=`pwd`
mkdir -p $dest
cd $work_dir

platforms=`ls *.json.template | sed "s/.json.template//g"`

for plat in $platforms
do

	version=`cat $plat.platform_version`
	for i in $version
	do
		sed "s|###platform_version###|$i|g" $plat.json.template > $c_dir/$dest/$plat-$i.json
	done
done

cd $c_dir

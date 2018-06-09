#!/bin/bash

# $1 - version
# $2 - destanation

dest=$2
version=$1

production_url=${production_url:-"https://downloads.mariadb.com/MaxScale/"}

dir=`pwd`
cd ~/mdbci/repository-config/maxscale-release/

mkdir -p $dir/$dest/maxscale-release

export deb_repo_key="135659e928c12247"
export rpm_repo_key=${production_url}/MariaDB-MaxScale-GPG-KEY

cat old_key_versions | grep "^$version$"
if [ $? == 0 ]; then
	echo "old key!"
	export deb_repo_key="70E4618A8167EE24"
	export rpm_repo_key=${production_url}/old_key.public
fi


export platforms=`ls -1 | grep template | sed "s/\.json\.template//"`

for platform in $platforms
do
	export platform_versions=`cat $platform.platform_version`
	for platform_version in ${platform_versions}
	do
	  eval "cat <<EOF
$(<${platform}.json.template)
" 2> /dev/null > $dir/$dest/maxscale-release/${platform}_${platform_version}_$version.json
	done
done

cd $dir

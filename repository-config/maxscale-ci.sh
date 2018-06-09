#!/bin/bash

# $1 - ci target name
# $2 - destanation

dest=$2
ci=$1

ci_url=${ci_url:-"http://max-tst-01.mariadb.com/ci-repository/"}
production_url=${production_url:-"https://downloads.mariadb.com/MaxScale/"}

dir=`pwd`
cd ~/mdbci/repository-config/maxscale-ci/

mkdir -p $dir/$dest/maxscale-ci

export deb_repo_key="135659e928c12247"
export rpm_repo_key=${production_url}/MariaDB-MaxScale-GPG-KEY

export platforms=`ls -1 | grep template | sed "s/\.json\.template//"`

for platform in $platforms
do
	export platform_versions=`cat  $platform.platform_version`
	for platform_version in ${platform_versions}
	do
		  eval "cat <<EOF
$(<$platform.json.template)
" 2> /dev/null > $dir/$dest/maxscale-ci/${platform}_${platform_version}_$ci.json
	done
done

cd $dir

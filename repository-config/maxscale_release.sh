#!/bin/bash

# $1 - url to release downloads
# $2 - destanation
# $3 - repo path

get_release_versions () {
  # $1 - repo path
  # $2 - url to release downloads
  repo=$3
  base_url=$1
  tags=`git ls-remote --tags $repo | grep -o -P '(?<=tags\/maxscale-).*(?=\^)'`
  release_versions=()
  for tag in $tags
  do
  	url="$base_url$tag/"
  	if curl --output /dev/null --silent --head --fail "$url"; then
      release_versions+=($tag)
      url="$base_url$tag-debug/"
      	if curl --output /dev/null --silent --head --fail "$url"; then
          release_versions+=("$tag-debug")
        fi
    fi
    tag=${tag::${#tag}-2}
    url="$base_url$tag/"
    if curl --output /dev/null --silent --head --fail "$url"; then
      release_versions+=($tag)
      url="$base_url$tag-debug/"
      	if curl --output /dev/null --silent --head --fail "$url"; then
          release_versions+=("$tag-debug")
        fi
    fi
  done
  echo ${release_versions[@]}
}

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

vers=$(get_release_versions $repo $downloads_url)

for f in $list
do
    for ver in ${vers[@]}
    do
	echo $f $ver
        sed "s|###version###|$ver|g" $dest/maxscale-release-templates-versions/$f  > $dest/maxscale-release/${ver}_${f}
    done
done

rm -rf $dest/maxscale-release-templates-versions

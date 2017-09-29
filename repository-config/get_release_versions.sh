#!/bin/bash

# $1 - repo path
# $2 - url to release downloads

function get_version_with_check_url () {
  release_version=()
  url=$1
  if curl --output /dev/null --silent --head --fail "$url"; then
    release_version+=("$tag")
    url="$base_url$tag-debug/"
      if curl --output /dev/null --silent --head --fail "$url"; then
        release_version+=("$tag-debug")
      fi
  fi
  echo ${release_version[@]}
}

function is_not_contains () {
  search=$1
  shift
  array=("${@}")
  for i in "${array[@]}"
  do
    if [ "$i" == "$search" ] ; then
        return 1
    fi
  done
  return 0
}

repo=$1
base_url=$2
tags=`git ls-remote --tags $repo | grep -o -P '(?<=tags\/maxscale-).*(?=\^)'`
release_versions=()
for tag in $tags
do
  url="$base_url$tag/"
  release_versions+=($(get_version_with_check_url $url))
  tag=${tag::${#tag}-2}
  if is_not_contains "$tag" "${release_versions[@]}" ; then
    url="$base_url$tag/"
    release_versions+=($(get_version_with_check_url $url))    
  fi
done
echo ${release_versions[@]}
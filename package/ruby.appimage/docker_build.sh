#!/bin/bash
# This script creates docker image and builds the applicaiton inside it
set -xe

script_dir="${0%/*}"
app_dir="$(pwd)"

# Go to the directory of the script
pushd $script_dir

# Create docker image to build application inside it
docker build \
       --build-arg UID=$(id -u) \
       --build-arg GID=$(id -g) \
       --force-rm \
       -t ruby-appimage:latest .

docker run -it \
       -e DOCKER_BUILD=true \
       --user $(id -u):$(id -g) \
       -v "$app_dir":/workspace/application \
       ruby-appimage:latest \
       ../gen_appimage.sh "$@"
popd

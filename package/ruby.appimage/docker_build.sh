#!/bin/bash
# This script creates docker image and builds the applicaiton inside it
set -xe

script_dir="${0%/*}"
app_dir="$(pwd)"

# Go to the directory of the script
pushd $script_dir

docker pull ubuntu:14.04

# Create docker image to build application inside it
docker build \
       --no-cache \
       --build-arg UID=$(id -u) \
       --build-arg GID=$(id -g) \
       -t ruby-appimage:latest .

docker run \
       -e DOCKER_BUILD=true \
       --user $(id -u):$(id -g) \
       -v "$app_dir":/workspace/application \
       ruby-appimage:latest \
       ../gen_appimage.sh "$@"
popd

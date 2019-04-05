#!/bin/bash
# This script bundles the mdbci as the AppImage.
# You should pass the build version as the parameter to the script.
# Resulting file will reside in build/out subdirectory
set -e

BUILD_VERSION=$1

if [ -z "$BUILD_VERSION" ]; then
  cat <<EOF
Please specify the release name as the first parameter to the script:
$0 VERSION
EOF
  exit 1
fi

CURRENT_DIR="$(pwd)"

BUILD_DIR="$(pwd)/build"
if [ -d "$BUILD_DIR" ]; then
  rm -rf "$BUILD_DIR"
fi
mkdir -p "$BUILD_DIR"

# Copy all files that should be distributed to the build directory
MDBCI_BUILD_DIR="$BUILD_DIR/mdbci"
mkdir -p "$MDBCI_BUILD_DIR"
for file in config confs core docs Gemfile Gemfile.lock mdbci recipes scripts
do
  cp -r "../$file" "$MDBCI_BUILD_DIR/"
done

# Copy all files required by ruby.appimage
for file in mdbci.desktop mdbci.png mdbci.sh
do
  cp "$file" "$BUILD_DIR/"
done

# Copy the runner directory to the build
cp -r "runner" "$BUILD_DIR/"

# Put the version information into the build
pushd ..
version=$(git rev-parse HEAD)
time=$(date +%F)
echo "${BUILD_VERSION}, ${version}, ${time}" > $MDBCI_BUILD_DIR/version
popd

# Start the build using ruby.appimage
pushd $BUILD_DIR
"$CURRENT_DIR/ruby.appimage/docker_build.sh" mdbci $BUILD_VERSION
popd

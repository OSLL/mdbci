#!/bin/bash

########################################################################
# Package the binaries built as an AppImage
# By Simon Peter 2016
# For more information, see http://appimage.org/
########################################################################

# replace paths in binary file, padding paths with /
# usage: replace_paths_in_file FILE PATTERN REPLACEMENT
replace_paths_in_file () {
    local file="$1"
    local pattern="$2"
    local replacement="$3"
    if [[ ${#pattern} -lt ${#replacement} ]]; then
        echo "New path '$replacement' is longer than '$pattern'. Exiting."
        return
    fi
    while [[ ${#pattern} -gt ${#replacement} ]]; do
        replacement="${replacement}/"
    done
    echo -n "Replacing $pattern with $replacement ... "
    sed -i -e "s|$pattern|$replacement|g" $file
    echo "Done!"
}

# modify shell-based ruby executables so they will use
# proper ruby executable and run from the usr/ directory.
# This script correctly modifies executables in $APP_DIR/usr/bin
insert_run_header() {
    local file="$1"
    read -d '' header <<'HEADER' || true
#!/bin/bash
# -*- ruby -*-
bindir=$( cd "${0%/*}"; pwd )
executable=$bindir/${0##*/}
exec ruby -x "$executable" "$@"
HEADER
    ex -sc "1i|$header" -cx $file
}

# App arch, used by generate_appimage.
if [ -z "$ARCH" ]; then
    export ARCH="$(arch)"
fi

# App name, used by generate_appimage.
if [ "$#" -eq 0 ]; then
    APP=ruby
    VERSION=2.6.3
    EXTRA_APP=false
elif [ "$#" -eq 2 ]; then
    APP=$1
    VERSION=$2
    EXTRA_APP=true
else
    cat <<EOF
Invalid number of parameters have been passed to the script.

Usage: "$0" [app] [version]

app - name of the application to package.
verision - version to use during the packaging.

If you specify the name of the application, please provide
app.sh file that will bundle the application into the appimage.
EOF
    exit
fi

ROOT_DIR="$PWD"
BUILD_DIR="$PWD/build"
APP_DIR="$BUILD_DIR/$APP.AppDir"
if [ -d $APP_DIR ]; then
    echo "--> cleaning up the AppDir"
    rm -rf $APP_DIR
fi
mkdir -p $APP_DIR

# Go into the build directory, so we will not create a mess inside
# the source directory
pushd $BUILD_DIR

RUBY_VERSION=2.6.3
RUBY_SHORT_VERSION=$(echo $RUBY_VERSION | awk -F. '{print $1"."$2}')
RUBY_DIR=ruby-$RUBY_VERSION
if [ -d $RUBY_DIR ]; then
    echo "--> removing old ruby directory"
    rm -rf $RUBY_DIR
fi

RUBY_ARCHIVE=$RUBY_DIR.tar.xz
if [ ! -f $RUBY_ARCHIVE ]; then
    echo "--> get ruby source"
    wget http://cache.ruby-lang.org/pub/ruby/$RUBY_SHORT_VERSION/$RUBY_DIR.tar.xz -O $RUBY_DIR.tar.xz -O $RUBY_ARCHIVE
fi
echo "--> unpacking ruby archive"
tar xf $RUBY_ARCHIVE

echo "--> compile Ruby and install it into AppDir"
pushd $RUBY_DIR
./configure --prefix=$APP_DIR/usr --disable-install-doc --disable-debug --disable-dependency-tracking --enable-shared --enable-load-relative
CPU_NUMBER=$(grep -c '^processor' /proc/cpuinfo)
CFLAGS="-O3" make -j$CPU_NUMBER
make install
popd # Leaving ruby directory after compilation

echo "--> patch away absolute path in scripts"
for SCRIPT in erb gem irb rake
do
    insert_run_header "$APP_DIR/usr/bin/$SCRIPT"
done

popd # Leaving build subdirectory when calling external script

# Configuring CPATH variable
export CPPFLAGS="-I${APP_DIR}/usr/include -I${APP_DIR}/usr/include/libxml2"
export CFLAGS="${CPPFLAGS}"
export LDFLAGS="-L${APP_DIR}/usr/lib -L${APP_DIR}/usr/lib64"
export PATH="$APP_DIR/usr/bin:$PATH"
export CPATH="$APP_DIR/usr/include"
export LD_LIBRARY_PATH="$APP_DIR/usr/lib"

if [ "$EXTRA_APP" == "true" ]; then
    echo "--> installing extra application"
    . ./$APP.sh
fi

if [ -z "$SKIP_BUILD" ]; then

pushd $BUILD_DIR # Going back in order for scripts to work

echo "--> remove unused files"
# remove doc, man, ri
rm -rf $APP_DIR/usr/share/{doc, man}
# remove ruby headers
rm -rf $APP_DIR/usr/include

########################################################################
# Get helper functions and move to AppDir
########################################################################
wget -q https://github.com/AppImage/AppImages/raw/master/functions.sh -O ./functions.sh
. ./functions.sh

pushd $APP_DIR

echo "--> get AppRun"
# get_apprun Do not use it currently due to the bug
get_stable_apprun()
{
  TARGET_ARCH=${ARCH:-$SYSTEM_ARCH}
  wget -c https://github.com/AppImage/AppImageKit/releases/download/10/AppRun-${TARGET_ARCH} -O AppRun
  chmod a+x AppRun
}
if [ ! -x AppRun ]; then
  get_stable_apprun
fi

echo "--> get desktop file and icon"
cp $ROOT_DIR/$APP.desktop $ROOT_DIR/$APP.png .

echo "--> copy dependencies"
copy_deps
copy_deps # Double time to be sure

if [ -d ${APP_DIR}/home ]; then
  # Move home directory to the concrete place
  echo "--> copying home directory"
  rm -rf ${ROOT_DIR}/out/home
  mkdir -p ${ROOT_DIR}/out
  mv ${APP_DIR}/home ${ROOT_DIR}/out
fi

echo "--> move the libraries to usr/bin"
move_lib

echo "--> delete stuff that should not go into the AppImage."
delete_blacklisted

popd

########################################################################
# AppDir complete. Now package it as an AppImage.
########################################################################

echo "--> generate AppImage"
#   - Expects: $ARCH, $APP, $VERSION env vars
#   - Expects: ./$APP.AppDir/ directory
generate_type2_appimage

echo '==> finished'

popd

fi

#!/bin/bash

insert_mdbci_run_header() {
    local file="$1"
    read -d '' header <<'HEADER' || true
#!/bin/bash
# -*- ruby -*-
bindir=$( cd "${0%/*}"; pwd )
executable=$bindir/${0##*/}
# switch to correct gem home before running the executable
export APP_DIR=$( cd $bindir/..; pwd )
. $APP_DIR/share/gem_home/gem_home.sh
gem_home $APP_DIR/../mdbci-gems
exec ruby -x "$executable" "$@"
HEADER
    ex -sc "1i|$header" -cx $file
}

echo "--> installing gem_home to manage gem home for ruby applications"
wget -O gem_home-0.1.0.tar.gz https://github.com/postmodern/gem_home/archive/v0.1.0.tar.gz
tar -xzvf gem_home-0.1.0.tar.gz
pushd gem_home-0.1.0/
PREFIX=$APP_DIR/usr make install
. $APP_DIR/usr/share/gem_home/gem_home.sh
popd

echo "--> creating gem_home for mdbci"
mkdir $APP_DIR/mdbci-gems

echo "--> copying mdbci sources"
cp -r mdbci $APP_DIR/

echo "--> installing mdbci dependencies"
pushd $APP_DIR/mdbci
gem_home $APP_DIR/mdbci-gems
gem install bundler --no-document
insert_run_header $(which bundle)
insert_run_header $(which bundler)
bundle install --without development
gem_home -
popd

echo "--> creating symlink and fixing path to ruby"
pushd $APP_DIR/usr/bin
ln -sf ../../mdbci/mdbci mdbci
insert_mdbci_run_header mdbci
popd

echo "--> downloading certificates to the "
wget -O $APP_DIR/cacert.pem https://curl.haxx.se/ca/cacert.pem

echo "--> creating and installing custom runner"
sudo apt-get install -y cmake
pushd runner/
cmake .
make
cp AppRun $APP_DIR
popd

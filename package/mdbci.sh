#!/bin/bash

echo "--> copying mdbci sources"
cp -r mdbci $APP_DIR/

echo "--> installing mdbci dependencies"
pushd $APP_DIR/mdbci
gem install bundler --no-document
insert_run_header $APP_DIR/usr/bin/bundle
insert_run_header $APP_DIR/usr/bin/bundler
bundle install --without development --gemfile=$APP_DIR/mdbci/Gemfile
popd

echo "--> creating symlink and fixing path to ruby"
pushd $APP_DIR/usr/bin
ln -sf ../../mdbci/mdbci mdbci
insert_run_header mdbci
popd

echo "--> creating and insalling custom runner"
sudo apt-get install -y cmake
pushd runner/
cmake .
make
cp AppRun $APP_DIR
popd

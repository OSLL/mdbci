#!/bin/bash

echo "--> copying mdbci sources"
cp -r mdbci $APP_DIR/

echo "--> installing mdbci dependencies"
pushd $APP_DIR/mdbci
$APP_DIR/usr/bin/gem install bundler --no-document
insert_run_header $APP_DIR/usr/bin/bundle
$APP_DIR/usr/bin/bundle install --without development --gemfile=$APP_DIR/mdbci/Gemfile
popd

echo "--> creating symlink and fixing path to ruby"
pushd $APP_DIR/usr/bin
ln -sf ../../mdbci/mdbci mdbci
insert_run_header mdbci
popd

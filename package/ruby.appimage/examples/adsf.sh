#!/bin/bash
# This script will be executed as a part of the appimage build script

echo "--> install adsf gem"
$APP_DIR/usr/bin/gem install adsf -v 1.4.1 --no-document
insert_run_header $APP_DIR/usr/bin/adsf

#!/bin/bash

insert_mdbci_run_header() {
    local file="$1"
    read -d '' header <<'HEADER' || true
#!/bin/sh
# -*- ruby -*-
bindir=$( cd "${0%/*}"; pwd )
executable=$bindir/${0##*/}
# switch to correct gem home before running the executable
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

echo "--> creating and insalling custom runner"
sudo apt-get install -y cmake
pushd runner/
cmake .
make
cp AppRun $APP_DIR
popd

# Copied from the install_vagrant.sh script from vagrant-installers repository
echo "--> installing vagrant"
mkdir -p $APP_DIR/vagrant-gems
gem_home $APP_DIR/vagrant-gems
gem env
sleep 10
VAGRANT_REV=2.1.5

# Download Vagrant and extract
SOURCE_PREFIX="vagrant"
SOURCE_URL="https://github.com/hashicorp/vagrant/archive/v${VAGRANT_REV}.tar.gz"
wget -c ${SOURCE_URL} -O vagrant.tar.gz

rm -rf ${SOURCE_PREFIX}-*
tar xzf vagrant.tar.gz
rm vagrant.tar.gz
pushd ${SOURCE_PREFIX}-*

# If we have a version file, use that. Otherwise, use a timestamp
# on version 0.1.
if [ ! -f "version.txt" ]; then
  echo -n "0.1.0" > version.txt
fi

# Build the gem
gem build vagrant.gemspec
cp vagrant-*.gem vagrant.gem

# Install the pkg-config gem to ensure system can read the bundled *.pc files
gem install pkg-config --no-document -v "~> 1.1.7"

gem install vagrant.gem --no-document
gem_home -
popd

# Copy the vagrant runner script
cp vagrant ${APP_DIR}/usr/bin/
chmod 755 ${APP_DIR}/usr/bin/vagrant

# Install extensions
sudo apt-get install -y libxml2-dev libcurl4-openssl-dev libvirt-dev
vagrant plugin install vagrant-libvirt --plugin-version 0.0.43
vagrant plugin install vagrant-aws --plugin-version 0.7.2

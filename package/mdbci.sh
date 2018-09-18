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

# Copied from the install_vagrant.sh script from vagrant-installers repository
echo "--> installing vagrant"
GEM_COMMAND=gem
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
${GEM_COMMAND} build vagrant.gemspec
cp vagrant-*.gem vagrant.gem

# Install the pkg-config gem to ensure system can read the bundled *.pc files
${GEM_COMMAND} install pkg-config --no-document -v "~> 1.1.7"

${GEM_COMMAND} install vagrant.gem --no-document

# Install extensions
sudo apt-get install -y libxml2-dev libcurl4-openssl-dev libvirt-dev
${GEM_COMMAND} install vagrant-libvirt -v 0.0.43 --force --no-document --conservative --clear-sources
${GEM_COMMAND} install vagrant-aws -v 0.7.2 --force --no-document --conservative --clear-sources

CONFIG_DIR=${APP_DIR}/usr

# Setup the system plugins
cat <<EOF >${CONFIG_DIR}/plugins.json
{
  "version": "1",
  "installed": {
     "vagrant-aws": {
       "vagrant_version": "$VAGRANT_REV",
       "installed_gem_version": "0.7.2"
     },
     "vagrant-libvirt": {
       "vagrant_version": "$VAGRANT_REV",
       "installed_gem_version": "0.0.43"
     }
  }
}
EOF
chmod 0644 ${CONFIG_DIR}/plugins.json

popd

# Copy the vagrant runner script
cp vagrant ${APP_DIR}/usr/bin/
chmod 755 ${APP_DIR}/usr/bin/vagrant

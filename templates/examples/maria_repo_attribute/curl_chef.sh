#!/bin/bash

echo "Install curl..."
sudo apt-get install -y curl

echo "Get last chef..."
curl -L https://www.opscode.com/chef/install.sh > chef.sh

echo "Install chef..."
chmod +x chef.sh
sudo ./chef.sh

echo "Chef version..."
chef-solo -v


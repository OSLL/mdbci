#!/bin/bash

echo "Check if curl installed..."
chef_=$(which curl)	# /usr/bin/chef-solo
echo "CHEF: $chef_"
if [ $chef_='' ]; then
	echo "Get last chef..."
	curl -L https://www.opscode.com/chef/install.sh > chef.sh
	echo "Install chef..."
	chmod +x chef.sh
	sudo ./chef.sh
	echo "Chef version..."
	chef-solo -v
else
	echo "Chef installed!"
fi

#!/bin/bash
# This script installs the Amazon Web Services CLI and
# configures it in the interactive way.

# Get the location of the script and go into that directory.
script_dir=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)
cd $script_dir

# Install the python and pip onto the system
sudo apt install -y python-pip

# Intsall latest vernion of AWS CLI
sudo pip install --upgrade awscli
# Check that AWS credentials are set for MDBCI
aws --profile mdbci iam get-user
if [[ $? != 0 ]]; then
  aws --profile mdbci configure
fi
# Create security group and update aws-config.yml file
./update_aws_config_security_group.sh $(hostname)_$(date +%s)

#!/bin/bash 

# AWS CLI tool
sudo pip install --upgrade awscli
# Check AWS CLI credentials
aws --profile mdbci iam get-user
if [[ $? != 0 ]]; then
  aws --profile mdbci configure
fi
# Create security group and update aws-config.yml file
./scripts/update_aws_config_security_group.sh hostname_$(date +%s)

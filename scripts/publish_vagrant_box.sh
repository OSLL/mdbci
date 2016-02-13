#!/bin/bash

# TODO Don't tested!

# scripts params
if [[ "$#" == "5" ]]
then
    username = "$1";
    box_name = "$2";
    version = "$3";
    provider_name = "$4";
    access_token = "$5";
else
    username = 'h05t'
    box_name = 'ubuntu_trusty'
    version = '1.0.0'
    provider_name = 'virtualbox'
    access_token = 'NULL' # get by link https://vagrantcloud.com/settings/tokens
fi

# get upload_path by user token
prepare_upload_cmd='curl \"https://atlas.hashicorp.com/api/v1/box/$username/$box_name/version/$version/provider/$provider_name/upload?access_token=$access_token\"';

# get output
token_var='echo $prepare_upload_cmd | grep -Po '"\w+"' | grep -v "$token"';
echo "Upload token: $token_var"
upload_path_var='echo $prepare_upload_cmd | grep -Po '"\w+"' | grep -v "$upload_path"';
echo "Upload path: $upload_path_var";

# upload box
upload_cmd='curl -X PUT --upload-file foo.box $upload_path_var'
sleep 60s

# check for success upload
check_upload_cmd='curl 'https://atlas.hashicorp.com/api/v1/box/$usename/$box_name/version/$version/provider/$provider_name?access_token=$token_var''


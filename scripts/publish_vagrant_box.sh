#!/bin/bash

# TODO #6777 Task

while [[ $# > 1 ]]
do
key="$1"

case $key in
    -u|--user)
    USER="$2"
    shift # user
    ;;
    -b|--boxname)
    BOXNAME="$2"
    shift # box name
    ;;
    -v|--version)
    VERSION="$2"
    shift # version
    ;;
    -p|--provider)
    PROVIDER="$2"
    shift # provider name
    ;;
    -t|--token)
    TOKEN="$2"
    shift # user token
    ;;
    *)
            # unknown option
    ;;
esac
shift # past argument or value
done

echo USER       = "${USER}"
echo BOXNAME    = "${BOXNAME}"
echo VERSION    = "${VERSION}"
echo PROVIDER   = "${PROVIDER}"
echo TOKEN      = "${TOKEN}"

# get upload_path by user token
prepare_upload_cmd=$(curl "https://atlas.hashicorp.com/api/v1/box/${USER}/${BOXNAME}/version/${VERSION}/provider/${PROVIDER}/upload?access_token=${TOKEN}");
echo ${prepare_upload_cmd}

# TODO
# get output
#token_var=$(echo ${prepare_upload_cmd} | grep -Po '"\w+"' | grep -v \"$token\");
#echo "Upload token: $token_var"
#upload_path_var=$(echo ${prepare_upload_cmd} | grep -Po '"\w+"' | grep -v \"$upload_path\");
#echo "Upload path: $upload_path_var";| grep -Po '"\w+"'
errors=$(echo ${prepare_upload_cmd} | grep -Po '"\w+"' | grep -v \"errors\");
echo "errors: ${errors}";

# upload box
#upload_cmd=$(curl -X PUT --upload-file foo.box $upload_path_var)

# wait while box will be uploaded
#sleep 60s

# check for success upload
#check_upload_cmd=$(curl "https://atlas.hashicorp.com/api/v1/box/${USER}/${BOXNAME}/version/${VERSION}/provider/${PROVIDER}?access_token=${token_var}")


#!/bin/bash

# Usage 
# ./scripts/build_parser/coredump_finder.sh run_test-200 url

if [ $# -ne 2 ];
then 
	echo "Script require two arguments: @build_id@ (<build_name>_<build_number>) and @output_format@ (url|files)"
	exit 1
fi

BASE_DIR="$HOME/"
LOGS_PATH="${BASE_DIR}LOGS"

buildId=${1}
showFileList=${2}

buildPath=$LOGS_PATH/${buildId}

# Checking that build exists
if [ ! -d "$buildPath" ]
then
	echo "Directory $buildPath does not exist, exiting."
	exit 1
fi

if [[ "$showFileList" == "url" ]]
then
	find $buildPath | grep core | sed -e "s|${BASE_DIR}|http://max-tst-01.mariadb.com/|"
	exit 0
fi
cd $buildPath
find ./ | grep core | sed -e 's|/[^/]*$|/*|g' 
cd - 2>&1 1>/dev/null

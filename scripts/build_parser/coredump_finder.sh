#!/bin/bash

# Usage 
# ./scripts/build_parser/coredump_finder.sh run_test-200 url

if [ $# -ne 2 ];
then 
	echo "Script require two arguments: @build_id@ (<build_name>_<build_number>) and @output_format@ (url|files)"
	exit 1
fi

BASE_DIR="/home/vagrant/"
LOGS_PATH="${BASE_DIR}LOGS"

buildId=${1}
showFileList=${2}

# HACK for *matrix* jobs
if [[ $buildId == *"matrix"* ]]
then
	buildNumber=`echo $buildId | grep -o '[0-9]*$'`
	buildName=`echo $buildId | sed -e 's/-[0-9]*$//'`
	buildId="$buildName/*-$buildNumber"
fi

if [[ "$showFileList" == "url" ]]
then
	find $LOGS_PATH/${buildId} | grep core | sed -e "s|${BASE_DIR}|http://max-tst-01.mariadb.com/|"
	exit 0
fi
find $LOGS_PATH/${buildId} | grep core 

#!/bin/bash

# Usage 
# ./scripts/build_parser/coredump_finder.sh 200 url

if [ $# -ne 2 ];
then 
	echo "Script require two arguments: run_test build number and output format (url or files)"
	exit 1
fi

BASE_DIR="/home/vagrant/"
LOGS_PATH="${BASE_DIR}LOGS"

run_testNumber=${1}
showFileList=${2}
if [[ "$showFileList" == "url" ]]
then
	find $LOGS_PATH/run_test-${run_testNumber} | grep core | sed -e "s|${BASE_DIR}|http://max-tst-01.mariadb.com/|"
	exit 0
fi
find $LOGS_PATH/run_test-${run_testNumber} | grep core 

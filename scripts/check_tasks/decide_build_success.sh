#!/bin/bash

echo "$FAIL_REASON"
if [ "$FAIL_REASON" != "SUCCESS" ] 
then
	exit 1
fi

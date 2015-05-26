#!/bin/bash

echo "Check if curl installed..."
curl_=$(which curl)	# /usr/bin/curl
echo "CURL: $curl_"
if [ $curl_='' ]; then
	echo "Install curl..."
	sudo apt-get install -y curl
else
	echo "Curl installed!"
fi


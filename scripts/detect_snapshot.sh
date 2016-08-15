#!/bin/bash

# Scripts that checking configuration from first command line argument for snapshot existance. If any snapshot exists it exits with 1, otherwise $?==0


if [ $# -ne 1 ];
then 
	echo "Not enough arguments"
	echo "Usage: ./scripts/detect_snapshot.sh CONFIGURATION_NAME"
	exit 1
fi

configuration=$1
# For each node in configuration
#   if mdbci snapshot list $? == 0 then exit 1

# Get list of nodes
cd ${configuration}
nodes=`for i in $(ls -d */); do echo ${i%%/}; done`
cd ..

# Iterating list of nodes
for node in $nodes
do
	# Checking individual node snapshots
	node_snapshots=`./mdbci snapshot list --path-to-nodes ${configuration} --node-name ${node} --silent | wc -l`
	if [[ "$?" == "0" &&  $node_snapshots != "1"  ]]
	then
		echo "Snapshot exists for ${configuration}/${node}"
		exit 1
	fi
done 

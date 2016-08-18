#!/bin/bash

NETWORK_CONFIG_FILE=$1
if ! [ -f $NETWORK_CONFIG_FILE ]; then
  echo $NETWORK_CONFIG_FILE not found!
  exit 1
fi

PATH_LENGHT=$[${#NETWORK_CONFIG_FILE}-15] # Path lenght without "_network_config".
if [[ $PATH_LENGHT -lt 1 ]]; then
  echo $NETWORK_CONFIG_FILE - wrong path! Example: DIR_network_config
  exit 1
fi

PATH_TO_CONFIG=${NETWORK_CONFIG_FILE:0:PATH_LENGHT}/.vagrant/machines # Cut path from filename.

ACCESS_TIME=$(stat --format=%X $NETWORK_CONFIG_FILE)
MODIFY_TIME=$(stat --format=%Y $NETWORK_CONFIG_FILE)
NETWORK_CONFIG_TIME=$([[ $ACCESS_TIME > $MODIFY_TIME ]] && echo "$ACCESS_TIME" || echo "$MODIFY_TIME")

IS_RELEVANCE=1

if ! [ -d $PATH_TO_CONFIG/ ]; then
  echo $PATH_TO_CONFIG not found!
  exit 1  
fi

if [[ ! $(find  $PATH_TO_CONFIG/*/*/synced_folders) ]]; then
  echo $NETWORK_CONFIG_FILE is NOT relevant: all nodes destroyed
  exit 1
fi

MODIFIED=( $(stat --format=%Y $PATH_TO_CONFIG/*/*/synced_folders) )
ACCESSED=( $(stat --format=%X $PATH_TO_CONFIG/*/*/synced_folders) )

for TIME in ${MODIFIED[@]}; do
  if [[ $TIME -gt $NETWORK_CONFIG_TIME ]]; then
    IS_RELEVANCE=0
    break
  fi     
done
 
for TIME in ${ACCESSED[@]}; do
  if [[ $TIME -gt $NETWORK_CONFIG_TIME ]]; then
    IS_RELEVANCE=0
    break
  fi
done

if [ $IS_RELEVANCE -ne 1 ]; then
  echo $NETWORK_CONFIG_FILE is NOT relevant
  exit 1
fi

echo $NETWORK_CONFIG_FILE is relevant
exit 0

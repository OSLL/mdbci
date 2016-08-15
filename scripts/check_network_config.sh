#! /bin/bash

NETWORK_CONFIG_FILE=$1
PATH_LENGHT=$[${#NETWORK_CONFIG_FILE}-15]
PATH_TO_CONFIG=${NETWORK_CONFIG_FILE:0:PATH_LENGHT}/.vagrant/machines
NETWORK_CONFIG_TIME=$(stat --format=%Y $NETWORK_CONFIG_FILE)
IS_RELEVANCE=1

if [ -d $PATH_TO_CONFIG/ ]; then
  if find  $PATH_TO_CONFIG/*/*/id > /dev/null 2>&1 ; then
    MODIFIED=( $(stat --format=%Y $PATH_TO_CONFIG/*/*/id) )
    for TIME in ${MODIFIED[@]}
    do
      if [[ $TIME -gt $NETWORK_CONFIG_TIME ]]; then
        IS_RELEVANCE=0
        break
      fi     
    done
    if [ $IS_RELEVANCE -eq 1 ]; then
      echo $NETWORK_CONFIG_FILE is relevant
      exit 0
    else
      echo $NETWORK_CONFIG_FILE is NOT relevant
    fi
  else
    echo $NETWORK_CONFIG_FILE is NOT relevant: all nodes destroyed
  fi
else
  echo $NETWORK_CONFIG_FILE not found!
fi
exit 1

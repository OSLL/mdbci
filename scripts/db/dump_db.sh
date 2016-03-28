#!/bin/bash

while getopts ":P:p:u:h:d:l:" opt; do
  case $opt in
    P) database_port="$OPTARG"
    ;;
    p) database_password="$OPTARG"
    ;;
    u) database_user="$OPTARG"
    ;;
    h) database_host="$OPTARG"
    ;;
    d) database_name="$OPTARG"
    ;;
    l) local_dump_file="$OPTARG"
    ;;
    \?) echo "Invalid option -$OPTARG" > &2
    ;;
  esac
done

error = 0

if [[ -z $local_dump_file ]]; then
  echo "Dump file must be specified" > &2
  error = 1
fi

if [[ -z $database_name ]]; then
  echo "Database name must be specified" > &2
  error = 1
fi

if [[ $error -ne 0 ]]; then
  exit $error
fi

if [[ -z $database_user ]]; then
  database_user="root"
fi

if [[ -n $database_user ]]; then
  database_password_option="-p$database_password"
fi

if [[ -n $database_port ]]; then
  database_port_option="-P $database_password"
fi

if [[ -n $database_host ]]; then
  database_host_option="-h $database_host"
fi

mysqldump $database_port_option $database_host_option -u $database_user $database_password_option > $local_dump_file

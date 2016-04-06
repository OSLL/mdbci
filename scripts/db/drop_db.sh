#!/bin/bash

while getopts "hP:p:u:H:d:l:" opt; do
  case $opt in
    P) database_port="$OPTARG"
    ;;
    p) database_password="$OPTARG"
    ;;
    u) database_user="$OPTARG"
    ;;
    H) database_host="$OPTARG"
    ;;
    d) database_name="$OPTARG"
    ;;
    h) show_help=true
    ;;
    \?) echo "Invalid option -$OPTARG" >&2
    ;;
  esac
done

if [[ $show_help ]]; then
  echo "USAGE: drop_db.sh -d DATABASE_NAME -l LOCAL_DUMP_FILE
    [-P database port]
    [-p database password]
    [-u database user]
    [-H database host]
    [-h help]"
  exit 0
fi

error=0

if [[ -z $database_name ]]; then
  echo "ERROR: Database name must be specified" >&2
  exit 1
fi

if [[ -z $database_user ]]; then
  database_user="root"
fi

if [[ -n $database_password ]]; then
  database_password_option="-p$database_password"
fi

if [[ -n $database_port ]]; then
  database_port_option="-P $database_port"
fi

if [[ -n $database_host ]]; then
  database_host_option="-h $database_host"
fi

mysql $database_port_option $database_host_option -u $database_user $database_password_option -e "DROP DATABASE IF EXISTS $database_name"

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
    l) local_dump_file="$OPTARG"
    ;;
    r) database_root_password="$OPTARG"
    ;;
    h) show_help=true
    ;;
    \?) echo "Invalid option -$OPTARG" >&2
    ;;
  esac
done

if [[ $show_help ]]; then
  echo \
"USAGE: import_db.sh -d DATABASE_NAME -l LOCAL_DUMP_FILE
    [-P database port]
    [-p database password]
    [-u database user]
    [-l local dump file]
    [-d database name]
    [-H database host]
    [-h help]"
  exit 0
fi

error=0

if [[ -z $local_dump_file ]]; then
  echo "ERROR: Dump file must be specified" >&2
  exit 1
fi

if [[ -z $database_name ]]; then
  echo "ERROR: Database name must be specified" >&2
  exit 1
fi

if [[ $error -ne 0 ]]; then
  exit $error
fi

if [[ -z $database_user ]]; then
  database_user="root"
fi

if [[ -n $database_password ]]; then
  database_password_option="-p$database_password"
fi

if [[ -n $database_root_password ]]; then
  database_root_password_option="-p$database_password"
fi

if [[ -n $database_port ]]; then
  database_port_option="-P $database_port"
fi

if [[ -n $database_host ]]; then
  database_host_option="-h $database_host"
fi

mysql $database_port_option $database_host_option -u root $database_root_password_option -e "GRANT ALL PRIVILEGES ON \`${database_name}\`.* TO '${database_user}'@'%' identified by '${database_password}';"
mysql $database_port_option $database_host_option -u root $database_root_password_option -e "GRANT ALL PRIVILEGES ON \`${database_name}\`.* TO '${database_user}'@'localhost' identified by '${database_password}';"
mysql $database_port_option $database_host_option -u $database_user $database_password_option -e "CREATE DATABASE IF NOT EXISTS $database_name"
mysql $database_port_option $database_host_option -u $database_user $database_password_option --database=$database_name < $local_dump_file

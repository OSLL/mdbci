#!/bin/bash

while getopts ":r:d:" opt; do
  case $opt in
    r) root_password="$OPTARG"
    ;;
    d) database_name="$OPTARG"
    ;;
    \?) echo "Invalid option -$OPTARG" >&2
    ;;
  esac
done

if [[ -n $root_password ]]; then
  mariadb_root_password_option="-p'$root_password'"
else
  mariadb_root_password_option=""
fi

if [[ -n $database_name ]]; then
  echo "Creating database $database_name..."
  echo "mysql -u root $mariadb_root_password_option -e \"CREATE DATABASE IF NOT EXISTS `$database_name`\""
  echo "Database created"
else
  echo "ERROR: Database name required"
  exit 1
fi

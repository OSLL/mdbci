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

if [[ -z $database_name ]]; then
  echo "ERROR: Database name must be specified" >&2
  exit 1
fi

iif [[ -z $database_user ]]; then
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

create_database_query = "CREATE DATABASE IF NOT EXISTS ${database_name};"

create_table_test_run="CREATE TABLE IF NOT EXISTS ${database_name} (
  id INT AUTO_INCREMENT,
  jenkins_id INT,
  start_time DATETIME,
  target VARCHAR(256),
  box VARCHAR(256),
  product VARCHAR(256),
  mariadb_version VARCHAR(256),
  test_code_commit_id VARCHAR(256),
  maxscale_commit_id VARCHAR(256),
  job_name VARCHAR(256),
  PRIMARY KEY(id)
);"

create_table_results="CREATE TABLE IF NOT EXISTS  results (
  id INT,
  test VARCHAR(256),
  result INT,
  FOREIGN KEY (id) REFERENCES test_run(id)
);"

mysql $database_port_option $database_host_option -u $database_user $database_password_option -e "${create_database}"
mysql $database_port_option $database_host_option -u $database_user $database_password_option -e "${create_table_results}"
mysql $database_port_option $database_host_option -u $database_user $database_password_option -e "${create_table_test_run}"

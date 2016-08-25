#! /bin/bash

while getopts ":s:n:" opt; do
  case ${opt} in
    s) silent="$OPTARG"
    ;;
    n) test_name="$OPTARG"
    ;;
    \?) silent="true" 
    ;;
  esac
done

if [[ ${silent} != "true" ]] && [[ ${silent} != "false" ]]; then
  silent=true
fi

if [[ -z "$test_name" ]]; then
  SILENT=$silent rake run_integration_parametrized_all
else
  SILENT=$silent rake "run_integration_parametrized:task_$test_name"
fi

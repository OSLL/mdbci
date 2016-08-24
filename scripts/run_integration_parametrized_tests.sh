#! /bin/bash

while getopts ":s:t:" opt; do
  case ${opt} in
    s) silent="$OPTARG"
    ;;
    t) test_set="$OPTARG"
    ;;
    \?) silent="true" 
    ;;
  esac
done

if [[ "$silent" != "true" ]] && [[ "$silent" != "false" ]]; then
  silent=true
fi

if [[ -z "$test_set" ]]; then
  SILENT="$silent" rake run_integration_parametrized_all
else
  tests=''
  for i in $(echo "$test_set" | sed "s/,/ /g"); do tests="$tests run_integration_parametrized:task_$i"; done
  SILENT=${silent} rake "$tests"
fi

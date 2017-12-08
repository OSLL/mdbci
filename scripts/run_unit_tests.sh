#! /bin/bash

while getopts ":s:" opt; do
  case $opt in
    s) silent="$OPTARG"
    ;;
    \?) silent="true"
    ;;
  esac
done

if [[ $silent != "true" ]] && [[ $silent != "false" ]]; then
  silent=true
fi

SILENT=$silent rake run_unit_all && rake spec

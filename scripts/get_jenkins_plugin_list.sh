#!/bin/bash

# Usage 
# ./scripts/get_jenkins_plugin_list.sh plugins_file.xml

if [ $# -ne 1 ]; then 
  echo "Script require one argument: @xml_file@"
  exit 1
fi

XML_FILE=${1}

if [ ! -f $XML_FILE ]; then
  echo "File $XML_FILE not exist!"
  exit 1
fi

pluginsList=`grep -oPm1 "(?<=<shortName>)[^<]+" $XML_FILE`
sortedPluginsList=($(echo ${pluginsList[*]}| tr " " "\n" | sort -n))

for plugin in "${sortedPluginsList[@]}"; do
  echo "$plugin"
done

exit 0
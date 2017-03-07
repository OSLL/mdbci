#!/bin/bash

function help {
    echo "Usage .scripts/jenkins_cli/install_plugins -s HOST(with protocol) -p PORT -f PATH_TO_FILE"
    echo ""
    echo "File content is lines with name and version devided by space"
    echo "Example:"
    echo "    ssh-credentials 1.13"
    echo "    ssh-credentials 1.13"
    echo "    ..."

}

safe_restart=false

while getopts ":s:p:f:a:rh" opt; do
  case $opt in
    s) host="$OPTARG"
    ;;
    p) port="$OPTARG"
    ;;
    f) file="$OPTARG"
    ;;
    a) attempts="$OPTARG"
    ;;
    r) safe_restart=true
    ;;
    h) help; exit 0
    ;;
    \?) echo "Invalid option -$OPTARG" >&2
        exit 1
    ;;
  esac
done

if [ -z "$host" ] || [ -z "$port" ] || [ -z "$file" ]; then
    echo 'All arguments must be specified!'
    help
    exit 1
fi

java -jar $HOME/jenkins-cli.jar -s $host:$port list-plugins > current_plugins.temp
sed -i 's|(.*)||g' current_plugins.temp
awk -F' ' '{print $1 " " $NF}' current_plugins.temp > current_plugins
rm current_plugins.temp

if [ -z $attempts ]; then
  attempts=5
fi

cat "$file" &>/dev/null
if [ "$?" -ne "0" ]; then
    echo "Error: file not found - $file"
    exit 1
fi

function install_plugin {
  cmd="java -jar $HOME/jenkins-cli.jar -s $1:$2 install-plugin $3 -deploy"
  eval $cmd
  exit_code=$?
  if [ "$exit_code" -ne "0" ]; then
    echo "Error: command '$cmd' failed with code - $exit_code, skipping..."
    install_result=1
  else
    echo "Ok"
    install_result=0
  fi
}

failed_plugins_addresses=()
found_failed_plugins=false

while read line; do
    grep -Fxq "$line" current_plugins
    if [ $? -eq 0 ]; then
      echo "Plugin $line already installed"
    else
      echo "Plugin $line NOT installed, installing..."
      if [[ ! -z "${line// }" ]]; then
        name=$(echo $line | awk -F" " '{print $1}')
        version=$(echo $line | awk -F" " '{print $2}')
        address="http://mirrors.jenkins-ci.org/plugins/$name/$version/$name.hpi"
        install_plugin $host $port $address
        if [ "$install_result" -eq 1 ]; then
          failed_plugins_addresses+=($address)
          found_failed_plugins=true
        fi
        echo $result
      fi
    fi
done < "$file"

for i in $(seq 1 $attempts); do
  failed_plugins_addresses_temp=("${failed_plugins_addresses[@]}")
  unset $failed_plugins_addresses
  failed_plugins_addresses=()
  if $found_failed_plugins ; then
    echo "Trying ti install failed plugins, attempt: $i"
    found_failed_plugins=false
    echo "${failed_plugins_addresses_temp[@]}"
    for var in "${failed_plugins_addresses_temp[@]}"; do
      install_plugin $host $port "$var"
      if [ "$install_result" -eq 1 ]; then
        failed_plugins_addresses+=("$var")
        found_failed_plugins=true
      fi
    done
  else
    break
  fi
done

if [ ${#failed_plugins_addresses[@]} -ne 0 ]; then
  echo "Not all jenkins plugins installed from file $file"
  exit 1
else
  echo "All jenkins plugins installed from file $file"
  if $safe_restart ; then
    echo "Restarting jenkins"
    java -jar $HOME/jenkins-cli.jar -s $host:$port safe-restart
  fi
  exit
fi



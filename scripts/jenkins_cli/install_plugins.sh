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

while getopts ":s:p:f:h" opt; do
  case $opt in
    s) host="$OPTARG"
    ;;
    p) port="$OPTARG"
    ;;
    f) file="$OPTARG"
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

cat "$file" &>/dev/null
if [ "$?" -ne "0" ]; then
    echo "Error: file not found - $file"
    exit 1
fi

exit_code=0

while read line; do
    if [[ ! -z "${line// }" ]]; then
        name=$(echo $line | awk -F" " '{print $1}')
        version=$(echo $line | awk -F" " '{print $2}')
        address="https://updates.jenkins-ci.org/download/plugins/$name/$version/$name.hpi"
        if [ "$(curl -L --silent --output /dev/null $address --write-out '%{http_code}')" -ne '200' ]; then
            echo "Error: plugin not found - $name $version, skipping..."
            exit_code=1
            continue
        fi 
        java -jar "$HOME/jenkins-cli.jar" -s "$host:$port" install-plugin "$address"
        if [ "$?" -ne "0" ]; then
            echo "Error: command 'java -jar $HOME/jenkins-cli.jar -s $host:$port install-plugin $address' failed with code - $?"
            exit 1
        fi
    fi
done < "$file"

exit $exit_code

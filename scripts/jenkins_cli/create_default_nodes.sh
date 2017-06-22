#!/bin/bash


function help {
    echo "Usage ./scripts/jenkins_cli/create_default_nodes -s HOST(with protocol) -p PORT"
}

while getopts ":s:p:c:h" opt; do
  case $opt in
    s) host="$OPTARG"
    ;;
    p) port="$OPTARG"
    ;;
    h) help
       exit
    ;;
    \?) echo "Invalid option -$OPTARG" >&2
        exit 1
    ;;
  esac
done

java -jar $HOME/jenkins-cli.jar -s "${host}:${port}" create-credentials-by-xml system::system::jenkins _  < ./scripts/jenkins_cli/credentials_template.xml


for i in `ls ./scripts/jenkins_cli/nodes_templates/*`; do 
  java -jar $HOME/jenkins-cli.jar -s "${host}:${port}" create-node < $i
done

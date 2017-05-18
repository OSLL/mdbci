function help {
    echo "Usage ./scripts/jenkins_cli/import_views_from_max-tst-01.sh -s HOST(with protocol) -p PORT -d PATH_TO_SAVED_XML_CONFIGS"
}

while getopts ":s:p:h" opt; do
  case $opt in
    s) host="$OPTARG"
    ;;
    p) port="$OPTARG"
    ;;
    d) path_to_configs="$OPTARG"
    ;;
    h) help
       exit
    ;;
    \?) echo "Invalid option -$OPTARG" >&2
        exit 1
    ;;
  esac
done

if [ -z "$host" ] || [ -z "$port" ] || [ -z "$path_to_configs" ]; then
    echo 'All arguments must be specified!'
    help
    exit 1
fi

for config in $(ls "$path_to_configs" | grep ".xml"); do 
	java -jar $HOME/jenkins-cli.jar -s "$host:$port" create-view < "$path_to_configs/$config"
done


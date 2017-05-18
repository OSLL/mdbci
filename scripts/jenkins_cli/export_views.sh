function help {
    echo "Usage ./scripts/jenkins_cli/export_views -s HOST(with protocol) -p PORT -d PATH_TO_DIR_WITH_XML_CONFIGS -v VIEWS_NAMES(separated with space)"
}

while getopts ":s:p:d:v:h" opt; do
  case $opt in
    s) host="$OPTARG"
    ;;
    p) port="$OPTARG"
    ;;
    d) xml_configs_dir="$OPTARG"
    ;;
    v) views="$OPTARG"
    ;;
    h) help
       exit
    ;;
    \?) echo "Invalid option -$OPTARG" >&2
        exit 1
    ;;
  esac
done

if [ -z "$host" ] || [ -z "$port" ] || [ -z "$xml_configs_dir" ] || [ -z "$views" ]; then
    echo 'All arguments must be specified!'
    help
    exit 1
fi

for i in $(echo "$views"); do
	if [ ! -d "$xml_configs_dir" ]; then
		mkdir "$xml_configs_dir"
	fi
	java -jar $HOME/jenkins-cli.jar -s "$host:$port" get-view "$i" >  "$xml_configs_dir/$i.xml"
	if [ $? -eq 0 ]; then
		echo "view $i created at $xml_configs_dir/$i.xml"
	fi
done

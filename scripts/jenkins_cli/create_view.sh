#!/bin/bash



function help {
    echo "Usage ./scripts/jenkins_cli/create_view -s HOST(with protocol) -p PORT -v VIEW_NAME -j JOB_NAMES(devided with spaces)"
}

while getopts ":s:p:v:j:h" opt; do
  case $opt in
    s) host="$OPTARG"
    ;;
    p) port="$OPTARG"
    ;;
    v) view_name="$OPTARG"
    ;;
    j) job_names="$OPTARG"
    ;;
    h) help
       exit
    ;;
    \?) echo "Invalid option -$OPTARG" >&2
        exit 1
    ;;
  esac
done

if [ -z "$host" ] || [ -z "$port" ] || [ -z "$view_name" ] || [ -z "$job_names" ]; then
    echo 'All arguments must be specified!'
    help
    exit 1
fi

cp ./scripts/jenkins_cli/view_template.xml ./scripts/jenkins_cli/view_template.xml.temp

sed -i "s|#{VIEW_NAME}|$view_name|g" ./scripts/jenkins_cli/view_template.xml.temp

if ! java -jar "$HOME/jenkins-cli.jar" -s "$host:$port" create-view "$view_name" < ./scripts/jenkins_cli/view_template.xml.temp; then
    echo "Error: view - '$view_name' creation failed!"
    rm ./scripts/jenkins_cli/view_template.xml.temp
    exit 1
fi
rm ./scripts/jenkins_cli/view_template.xml.temp

echo "Success: view - '$view_name' has been created"

exit_code=0

while read -r line; do
    for job_name in $line; do
        if ! java -jar "$HOME/jenkins-cli.jar" -s "$host:$port" add-job-to-view "$view_name" "$job_name" &>/dev/null; then
            echo "Error: job - '$job_name' adding failed!"
            exit_code=1
            continue
        fi
        echo "Success: job - '$job_name' has been added to view - '$view_name'"
    done
done <<< $(echo "$job_names")

exit $exit_code

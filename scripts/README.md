## Boxes downloader usage

* run 'sudo gem install progressbar'
* create directory with boxes and make it available by adding next lines to /etc/apache2/apache2.conf
```
Alias "/URL_PATH" "/REAL_PATH_TO_BOXES"
<Directory "/REAL_PATH_TO_BOXES">
        Options Indexes FollowSymLinks
        AllowOverride None
        Require all granted
</Directory>
```
* Atlas box has format PLATFORM/PLATFORM_VERSION
* Atlas box url path has format https://atlas.hashicorp.com/PLATFORM/boxes/PLATFORM_VERSION/versions/BOX_VERSION/providers/PROVIDER.box
* Сreate boxes JSON file with alike below content.
```
{
  "debian" : {
    "provider": "virtualbox",
    "box": "URL_TO_BOX", 
    "box_version" : "BOX_VERSION",
    "platform": "debian",
    "platform_version": "wheezy"
  }
}
```
* run (use --force to rewrite already downloaded boxes)
```
./download_boxes.rb  --dir PATH_TO_DOWNLOADED_BOXES_DIRECTORY --boxes-dir PATH_TO_JSON_FILES_DIRECTORY
```

## Configuration slave
https://dev.osll.ru/projects/mdbci/wiki/Prepare_slave_for_run_test

## Setup nodes as on max-tst-01
0) Change directory into MDBCI directory

1) Write unique to _< id >_ tag in file **scripts/jenkins_cli/credentials_template.xml**

2) Change _< name >_ tag and put _< id >_ from previous step to into _< credentialsId >_ in file **scripts/jenkins_cli/nodes_templates/maxtst2.xml**

3) Repeat second step for file **scripts/jenkins_cli/nodes_templates/maxtst3.xml**

4) Run:
```
/scripts/jenkins_cli/create_default_nodes.sh -s http://localhost -p 8091
```
_Results_: new _< credentialsId >_ with id from first step and 2 slave nodes with _< name >_ from second and third steps.

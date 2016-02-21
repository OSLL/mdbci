Boxes downloader usage

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
* create boxes JSON file with alike content
```
{
  "debian" : {
    "provider": "virtualbox",
    "box": "URL_TO_BOX",
    "platform": "debian",
    "platform_version": "wheezy"
  }
}
```
* run (use --force to rewrite already downloaded boxes)
```
./download_boxes.rb  --dir PATH_TO_DOWNLOADED_BOXES_DIRECTORY --boxes_dir PATH_TO_JSON_FILES_DIRECTORY
```

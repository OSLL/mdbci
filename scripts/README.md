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

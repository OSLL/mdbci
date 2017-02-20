#!/bin/bash

script_name="resync_shared_dirs.sh"
if ! crontab -l -u ${USER} | grep -q ${script_name}
then
  echo "crontab is empty, adding line with ${script_name} call "
  line="* * * * * $HOME/mdbci/scripts/slave_setting/sshfs/${script_name}"
  (crontab -u ${USER} -l; echo "$line" ) | crontab -u ${USER} -
  exit 0
fi

echo "crontab already exists"

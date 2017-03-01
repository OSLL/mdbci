#!/bin/bash 

# This scripts check is one of the shared dirs unmounted and only in this case does:
#   scp local files to remote host
#   cleans local shared folder content
#   remounts remote shared folder

# repository repo LOGS
dirs=("repository" "repo" "LOGS")
echo "List of sshfs mounts:"
mount | grep sshfs


for dir_to_resync in "${dirs[@]}"
do

  LS_ERROR=$(ls LOGS 2>&1)
  LS_ERROR_MSG="ls: cannot access 'LOGS': Input/output error"

  if [ "$ERROR_MSG" = "$LS_ERROR" ] ; then
       fusermount -u LOGS
  fi

  echo "checking ${dir_to_resync}"
  if ! mount | grep sshfs | grep -q "${dir_to_resync} "
  then
    echo "\tdir $HOME/${dir_to_resync} is not mounted, resyncing (scp, clean, mount)"
    scp -r ${dir_to_resync}/* vagrant@max-tst-01.mariadb.com:/home/vagrant/${dir_to_resync}/
    echo "\tscp is done, preparing for cleaning local files"
    rm -rf $HOME/${dir_to_resync}/*
    echo "\tcleaning is done, preparing for mount"
    sshfs -o allow_other,reconnect vagrant@max-tst-01.mariadb.com:/home/vagrant/${dir_to_resync} $HOME/${dir_to_resync}
    echo "\tmount is done"
  else
    echo "\tdir $HOME/${dir_to_resync} is mounted, skipping."
  fi
done

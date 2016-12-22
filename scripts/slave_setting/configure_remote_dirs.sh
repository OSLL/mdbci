sudo apt-get install sshfs
./scripts/slave_setting/sshfs/check_resync_in_crone.sh

# Setting fstab
sshfs_conf_arr=("sshfs#vagrant@max-tst-01.mariadb.com:/home/vagrant/LOGS /home/vagrant/LOGS" "sshfs#vagrant@max-tst-01.mariadb.com:/home/vagrant/repo /home/vagrant/repo" "sshfs#vagrant@max-tst-01.mariadb.com:/home/vagrant/repository /home/vagrant/repository")
sudo cp '/etc/fstab' "/etc/fstab.$(($(date +%s%N)/1000000)).bak"
for var in "${sshfs_conf_arr[@]}"; do
    if [[ -z $(cat /etc/fstab | grep "$var") ]]; then
        if [[ "$var" == "${sshfs_conf_arr[0]}" ]]; then sudo sh -c "echo >> /etc/fstab"; fi
        sudo sh -c "echo '$var' >> /etc/fstab"
    fi
done

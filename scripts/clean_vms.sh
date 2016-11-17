# !/bin/bash

# $1 is prefix of the machines to be deleted
# $2
if [ ! -z $1 ]; then
    only_one_config=0
    if [[ (! -z $2) && ($2 == "-o")]]; then
        let only_one_config=1
        echo "First machine with prefix ${1} will be cleaned"
    else
        echo "Machine with prefixes ${1} will be cleaned"
    fi
#asd=(1 2 3 4 5)
    echo "Cleaning VirtuslBox machines"
#    for i in "${asd[@]}"; do
    for i in $(VBoxManage list vms | grep ${1} | grep -o '"[^\"]*"' | tr -d '"'); do
        echo $i
        VBoxManage controlvm $i poweroff
        VBoxManage unregistervm $i -delete
#        echo "$i"
        if [ $only_one_config == 1 ]; then
           break
        fi
    done

    echo "Cleaning libvirt machines"
    for i in $(virsh list --name --all | grep ${1}); do
      virsh shutdown $i
      virsh destroy $i
      for k in $(virsh snapshot-list ${i} --tree); do
          virsh snapshot-delete $i $k # i-domain; k-snapshot
      done
      virsh undefine $i
      if [ $only_one_config == 1 ]; then
           break
      fi
    done

    echo "Deleting libvirt machine's volumes"
    for i in $(virsh -q vol-list --pool default | grep $1 | awk '{print $1}'); do
      virsh vol-delete --pool default $i
      if [ $only_one_config == 1 ]; then
           break
      fi
    done

    echo "Cleaning docker machines"
    for i in $(docker ps --all -f "name=${1}" --format "{{.Names}}"); do
      docker rm -fv $i
      if [ $only_one_config == 1 ]; then
           break
      fi
    done

else
    echo "You need to define machine prefix as first argument!"
fi

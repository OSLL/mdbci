#!/bin/bash

# $1 is prefix of the machines to be deleted

if [ ! -z $1 ]; then

    echo "Machine with prefixes ${1} will be cleaned"

    echo "Cleaning VirtuslBox machines"
    for i in $(VBoxManage list vms | grep ${1} | grep -o '"[^\"]*"' | tr -d '"'); do
        echo $i
        VBoxManage controlvm $i poweroff
        VBoxManage unregistervm $i -delete
    done

    echo "Cleaning libvirt machines"
    for i in $(virsh list --name --all | grep ${1}); do
      virsh shutdown $i
      virsh destroy $i
      virsh undefine $i
    done

    echo "Deleting libvirt machine's volumes"
    for i in $(virsh -q vol-list --pool default | grep $1 | awk '{print $1}'); do
      virsh vol-delete --pool default $i
    done

    echo "Cleaning docker machines"
    for i in $(docker ps --all -f "name=${1}" --format "{{.Names}}"); do
      docker rm -v $i
    done

else
    echo "You need to define machine prefix as first argument!"
fi

# !/bin/bash

# $1 is prefix of the machines to be deleted
# $2 "-o" flag if need remove only one config (if $3 not specified - delete of all )
# $3 is prefix of provider, which first match config searching
# Provider prefixes:
## vbox or 1
## libvirt or 2
## docker or 3

if [ ! -z $1 ]; then
    only_one_config=0
    provider=0
    if [[ (! -z $2) && ($2 == "-o")]]; then
        let only_one_config=1
        if [[ (! -z $3) ]]; then
            case "$3" in
                "vbox" | "1" )
                    let provider=1
                ;;
                "libvirt" | "2" )
                    let provider=2
                ;;
                "docker" | "3" )
                    let provider=3
                ;;
                * )  
                    echo "Wrong provider prefix!"
                    exit 1
                ;;
            esac
            echo "First machine with prefix ${1} of selected provider will be cleaned"    
        else
            echo "First machine with prefix ${1} will be cleaned"            
        fi
    else
        echo "Machine with prefixes ${1} will be cleaned"
    fi

    if [[ $provider == 0 || $provider == 1 ]]; then
        echo "Cleaning VirtualBox machines"
        for i in $(VBoxManage list vms | grep ${1} | grep -o '"[^\"]*"' | tr -d '"'); do
            echo $i
            VBoxManage controlvm $i poweroff
            VBoxManage unregistervm $i -delete
            if [ $only_one_config == 1 ]; then
               break
            fi
        done
        if [[ $provider == 1 ]]; then exit 0; fi
    fi

    if [[ $provider == 0 || $provider == 2 ]]; then
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
        if [[ $provider == 2 ]]; then exit 0; fi
    fi

    if [[ $provider == 0 || $provider == 3 ]]; then
        echo "Cleaning docker machines"
        for i in $(docker ps --all -f "name=${1}" --format "{{.Names}}"); do
          docker rm -fv $i
          if [ $only_one_config == 1 ]; then
               break
          fi
        done
        if [[ $provider == 3 ]]; then exit 0; fi
    fi
else
    echo "You need to define machine prefix as first argument!"
fi

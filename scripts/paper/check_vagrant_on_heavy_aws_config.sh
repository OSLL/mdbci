#!/bin/bash 


# Generate configuration from confs/aws.json

configuration="aws_`date +%s`"
N=4
./mdbci --template confs/aws_special.json generate ${configuration}  --override

echo "N=$N"
 Execute N times with mdbci and vagrant
vagrant_fails=0
echo "Vagrant"
for i in $(seq 1 $N)
do
	cd ${configuration}
	vagrant up 2>&1 | tee "../${configuration}_log_vagrant_${i}"
	exit_code="$?"
	echo "$exit_code ($i/$N)" > "../${configuration}_vagrant_${i}"
	vagrant status >> "../${configuration}_vagrant_${i}"
	vagrant_fails=$(($vagrant_fails + $exit_code))
	vagrant destroy -f
	cd ..
done


mdbci_fails=0
echo "MDBCI"
for i in $(seq 1 $N)
do
	./mdbci up ${configuration} 2>&1 | tee "${configuration}_log_mdbci_${i}"
	exit_code="$?"
	echo "$exit_code ($i/$N)" > "${configuration}_mdbci_${i}"
	mdbci_fails=$(($mdbci_fails + $exit_code))
	cd ${configuration}
	vagrant status >> "../${configuration}_mdbci_${i}"
	vagrant destroy -f
	cd ..
done
# Print statistics
echo "vagrant_fails=\t$vagrant_fails"
echo "mdbci_fails=\t$mdbci_fails"

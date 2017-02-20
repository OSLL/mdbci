echo "test test1 21" | while read -r line; do 
	for i in $line; do
		echo $i
	done
done

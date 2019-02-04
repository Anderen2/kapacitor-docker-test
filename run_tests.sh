#!/bin/bash

function posttoinflux {
	status_code=$(curl -s -o /tmp/injecting -w "%{http_code}" -i -XPOST 'http://localhost:8086/write?db=telegraf' --data-binary "$@")
	if [ "$status_code" != "204" ]; then
		echo "Failed injecting data: $@"
		cat /tmp/injecting
		exit 3
	fi
}

for file in $(ls /testdata/); do
	echo "Injecting test data: $file"
	while read line; do 
		posttoinflux "$line"
	done < /testdata/$file
done

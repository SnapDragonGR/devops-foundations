#!/bin/bash

ping_count=1

while [ $ping_count -le 4 ]
do
    echo "Pinging server... attempt $ping_count."
    if [ $ping_count == 10 ]
    then
        echo "Host is alive!"
        exit 0
    fi
    ping_count=$(( $ping_count + 1))
    sleep 1
done

echo "Host unreachable."
exit 1
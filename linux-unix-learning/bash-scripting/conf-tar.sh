#!/bin/bash

for config in configs/*.conf
do
    if [ -f "$config" ]
    then
        cp "$config" "$config.bak"
        echo "Backed up $config to $config.bak"
    fi
done


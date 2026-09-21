#!/bin/bash

set -uo pipefail

if [ "$#" -eq 0 ]
then
    echo "Error: Missing file argument."
    exit 1
fi

file="$1"

if [ ! -f "$file" ]
then
    echo "Error: File not found."
    exit 2
elif [ ! -r "$file" ]
then
    echo "Error: File is not readable."
    exit 3
else
    echo "Success: File is ready."
    exit 0
fi

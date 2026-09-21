#!/bin/bash

check_file_exists() {
    if [ -f "$1" ]
    then
        return 0
    else
        return 1
    fi
}

if check_file_exists file.txt
then
    echo "File found!"
else
    echo "File not found!"
fi

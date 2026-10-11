#!/bin/bash

backup_file() {
    local file
    for file in "$@"
    do
        if [ -f "$file" ]
        then
            cp "$file" "$file.bak"
            echo "The backup file was successfully created."
        else
            echo "Error: $file does not exist."
        fi
    done
}

#!/bin/bash

if [ $# -ne 1 ]
then
    echo "Usage: ./check_service.sh <service_name>"
    exit 1
fi

if systemctl cat "$1" &> /dev/null
then
    if systemctl is-active "$1" &>> /dev/null
    then
        echo "Service $1 is running."
        exit 0
    else
        echo "Service $1 is not running."
        exit 1
    fi
else
    echo "Service does not exist."
    exit 2
fi


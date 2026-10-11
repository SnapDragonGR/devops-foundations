#!/bin/bash

if [ $# -ne 2 ]
then
    echo "Usage: backup.sh <source_dir> <target_dir>"
    echo "Please try again."
    exit 1
fi

if ! command -v rsync > /dev/null 2>&1
then
    echo "This script requires rsync to be installed."
    echo "Please use your distribution's package manager to install it and try again."
    exit 2
fi

current_date=$(date +%Y-%m-%d)

rsync_options="-avb --backup-dir $2/$current_date --delete"

$(which rsync) $rsync_options $1 $2/current >> backup_$current_date.log


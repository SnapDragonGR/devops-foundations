#!/bin/bash

release_file=/etc/os-release
logfile=/var/log/updater.log
errorlog=/var/log/updater_errors.log

check_exit_status() {
    if [ $? -ne 0 ]
    then
        echo "An error occurred, please check the $errorlog file."
        exit 1
    fi
}

if [ -f "$release_file" ] && [ -r "$release_file" ]
then
    if grep -q "Arch" "$release_file"; then
        sudo pacman -Syu &>>"$logfile"
    elif grep -q "Ubuntu" "$release_file" || grep -q "Debian" "$release_file"; then
        { sudo apt update && sudo apt dist-upgrade -y; } &>>"$logfile"
    elif grep -q "Fedora" "$release_file" || grep -q "rhel" "$release_file"; then
        sudo dnf upgrade -y &>>"$logfile"
    else
        echo "Unsupported operating system."
        exit 2
    fi
    check_exit_status
    echo "Update was successful. Enjoy"
else
    echo "os-release file not found."
    exit 1
fi
#!/bin/bash

release_file=/etc/os-release
logfile=/var/log/updater.log

run_update() {
    if "$@" &>>"$logfile"; then
        echo "Update was successful."
        return 0
    else
        echo "Update was not successful - check $logfile for logs."
        return 1
    fi
}

if [ -f "$release_file" ] && [ -r "$release_file" ]
then
    if grep -q "Arch" "$release_file"; then
        run_update sudo pacman -Syu
    elif grep -q "Ubuntu" "$release_file" || grep -q "Debian" "$release_file"; then
        run_update sudo apt update && run_update sudo apt dist-upgrade
    elif grep -q "Fedora" "$release_file" || grep -q "rhel" "$release_file"; then
        run_update sudo dnf upgrade
    else
        echo "Unsupported operating system."
        exit 2
    fi
else
    echo "os-release file not found."
    exit 1
fi

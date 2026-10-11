#!/bin/bash

if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root or with sudo."
    exit 1
fi

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

if [ -f "$release_file" ] && [ -r "$release_file" ]; then
    . "$release_file"
    case "$ID" in
        "arch") run_update pacman -Syu --noconfirm;;
        "debian" | "ubuntu") run_update apt update -y && run_update apt dist-upgrade -y;;
        "fedora" | "rhel") run_update dnf upgrade -y;;
        *)  echo "Unsupported operating system."
            exit 2
            ;;
    esac
else
    echo "os-release file not found."
    exit 1
fi

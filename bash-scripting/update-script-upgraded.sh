#!/bin/bash

release_file=/etc/os-release

if [ -f "$release_file" ] && [ -r "$release_file" ]
then
    if grep -q "Arch" "$release_file"; then
        sudo pacman -Syu
    elif grep -q "Ubuntu" "$release_file" || grep -q "Debian" "$release_file"; then
        sudo apt update && sudo apt dist-upgrade
    elif grep -q "Fedora" "$release_file" || grep -q "rhel" "$release_file"; then
        sudo dnf upgrade -y
    else
        echo "Unsupported operating system."
        exit 2
    fi
    if [ $? -ne 0 ]; then
        echo "Update was not successful."
        exit 1
    else
        echo "Update was successful. Enjoy"
    fi
else
    echo "os-release file not found."
    exit 1
fi
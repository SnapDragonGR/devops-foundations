#!/bin/bash

release_file=/etc/os-release

if grep -q "Arch" $release_file
then
    sudo pacman -Syu # update for arch
fi

if grep -q "Debian" $release_file || grep -q "Ubuntu" $release_file
then 
    sudo apt update # update for debian-based
    sudo apt dist-upgrade
fi

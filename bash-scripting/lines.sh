#!/bin/bash

lines=$(ls -lh $1 | wc -l)

if [ $# -ne 1 ]
then
    echo "One directory required."
    echo "Try again with a valid input."
    exit 1
fi

echo "You have $(($lines-1)) objects in the $1 directory."


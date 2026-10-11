#!/bin/bash

set -euo pipefail

if [ "$#" -ne 1 ]
then
    echo "Error: Please provide exactly one number representing CPU cores."
    exit 1
fi

CORES=$1

if [ $CORES -le 2 ]
then
    echo "Warning: $CORES cores is only enough for basic web servers."
elif [ $CORES -ge 3 ] && [ $CORES -le 8 ]
then
    echo "Optimal: $CORES cores is ready for a local Kubernetes cluster."
else
    echo "Overkill: $CORES cores is ready for heavy CI/CD pipelines."
fi



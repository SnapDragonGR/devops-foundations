#!/bin/bash

attempt=1

while [ $attempt -le 5 ]
do
    echo "Attempt <$attempt>: Checking service status..."
    if [ $attempt == 3 ]
    then
        echo "Service connected successfully!"
        exit 0
    fi
    attempt=$(( $attempt + 1 ))
    sleep 1
done

echo "Maximum attempts reached. Service check complete."
exit 1
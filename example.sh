#!/bin/sh 

sudo python3 autobooter.py
a=$?
if [ $a -gt 99 ]
then 
    echo "Failed to find port"
    exit 100 
elif [ $a -gt 0 ]
then
    echo "Failed to find device"
    exit 1 
fi
echo success
#fastboot reboot recovery

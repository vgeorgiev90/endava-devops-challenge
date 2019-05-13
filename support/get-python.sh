#!/bin/bash

if [ $# -gt 1 ];then

for i in $@;do
        ## AWS default user for ubuntu 18
        ssh -t ubuntu@${i} 'sudo apt-get install python-minimal -y'
done
else
        echo "Usage: ./get-python.sh IP1 IP2 IP3 .. .."
fi

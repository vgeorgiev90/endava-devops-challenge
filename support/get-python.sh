#!/bin/bash


if [ $# -eq 3 ];then

for i in ${1} ${2} ${3};do
	ssh -t ubuntu@${i} 'sudo apt-get install python-minimal -y'
done

else
	echo "Usage: ./get-python.sh IP1 IP2 IP3"
fi

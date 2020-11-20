#!/bin/bash


ZONE_ID=${1}
ENV=${2}


RABBIT_NAME=${ENV}-rabbit
AWS_CLI=$(which aws)

if [ -z $AWS_CLI ];then
	apt-get update; apt install python-pip -y
	pip install awscli
fi

TOKEN=`curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"`
LOCAL_IP=$(curl -H "X-aws-ec2-token: $TOKEN" -v http://169.254.169.254/latest/meta-data/local-ipv4)
INDEX=$(curl -H "X-aws-ec2-token: $TOKEN" -v http://169.254.169.254/latest/meta-data/ami-launch-index)
DNS_NAME="${RABBIT_NAME}${INDEX}.aws.cobrowser.io"


cat > /tmp/rabbit-record-set.json << EOF
                {
                  "Comment": "RabbitMQ Node: ${INDEX}",
                  "Changes": [{
                        "Action": "CREATE",
                        "ResourceRecordSet": {
                            "Name": "${DNS_NAME}",
                            "Type": "A",
			    "ResourceRecords": [{ "Value": "${LOCAL_IP}"}]
                              }
                          }]
                }
EOF

aws route53 change-resource-record-sets --hosted-zone-id ${ZONE_ID} --change-batch file:///tmp/rabbit-record-set.json



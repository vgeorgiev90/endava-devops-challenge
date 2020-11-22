#!/bin/bash

exec 1> /var/log/provisioning.log 2>&1
set -x

#### Get environment and Route53 Hosted Zone ID 
ZONE_ID="${zone}"
ENV="${env}"
ADMIN_PASS="${mongo_admin_pass}"


MONGO_NAME=$${ENV}-mongo
AWS_CLI=$(which aws)

if [ -z $AWS_CLI ];then
	apt-get update; apt install python-pip -y
	pip install awscli
fi

TOKEN=`curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"`
LOCAL_IP=`curl -H "X-aws-ec2-token: $TOKEN" -v http://169.254.169.254/latest/meta-data/local-ipv4`
BASE_DOMAIN=`aws route53 list-hosted-zones-by-name | grep $${ZONE_ID} -C 2 | grep -i name | awk -F":" '{print $2}' | awk -F"\"" '{print $2}'`

INDEX=0
DNS_NAME="$${MONGO_NAME}-$${INDEX}.$${BASE_DOMAIN::-1}"


cat > /tmp/mongo-record-set.json << EOF
                {
                  "Comment": "MONGODB Node: $${INDEX}",
                  "Changes": [{
                        "Action": "CREATE",
                        "ResourceRecordSet": {
                            "Name": "$${DNS_NAME}",
                            "Type": "A",
			    "TTL": 60, 
			    "ResourceRecords": [{ "Value": "$${LOCAL_IP}"}]
                              }
                          }]
                }
EOF
aws route53 change-resource-record-sets --hosted-zone-id $${ZONE_ID} --change-batch file:///tmp/mongo-record-set.json
result=$?

until [ $result -eq 0 ];do
        INDEX=$(($INDEX + 1))
        DNS_NAME="$${MONGO_NAME}-$${INDEX}.$${BASE_DOMAIN::-1}"
cat > /tmp/mongo-record-set.json << EOF
                {
                  "Comment": "ELASTICSEARCH Node: $${INDEX}",
                  "Changes": [{
                        "Action": "CREATE",
                        "ResourceRecordSet": {
                            "Name": "$${DNS_NAME}",
                            "Type": "A",
                            "TTL": 60,
                            "ResourceRecords": [{ "Value": "$${LOCAL_IP}"}]
                              }
                          }]
                }
EOF
aws route53 change-resource-record-sets --hosted-zone-id $${ZONE_ID} --change-batch file:///tmp/mongo-record-set.json 2>/dev/null 1>&2
result=$?
echo "DNS Record added with index: $${INDEX}"
done
hostnamectl set-hostname $${DNS_NAME}
snap install yq
chown -R mongodb:mongodb /etc/mongodb/
chmod 750 /etc/mongodb
chmod 600 /etc/mongodb/mongo.key

cat /etc/mongod.conf \
   | yq w - security.keyFile /etc/mongodb/mongo.key \
   | yq w - replication.replSetName rs$${INDEX} \
   | tee /tmp/mongod

rm /etc/mongod.conf -rf && mv /tmp/mongod /etc/mongod.conf && chmod 644 /etc/mongod.conf

systemctl enable mongod
systemctl restart mongod

sleep 20
if [ $${INDEX} -eq 0 ];then
	mongo --username siteRootAdmin --password $${ADMIN_PASS} --eval 'rs.initiate( {_id : "$${MONGO_NAME}",members: [{ _id: 0, host: "$${MONGO_NAME}-0.$${BASE_DOMAIN::-1}:27017" },{ _id: 1, host: "$${MONGO_NAME}-1.$${BASE_DOMAIN::-1}:27017" },{ _id: 2, host: "$${MONGO_NAME}-2.$${BASE_DOMAIN::-1}:27017" }]});'
fi






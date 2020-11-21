#!/bin/bash

exec 1> /var/log/provisioning.log 2>&1
set -x

#### Get environment and Route53 Hosted Zone ID 
ZONE_ID="${zone}"
ENV="${env}"

ELASTIC_NAME=$${ENV}-elastic
AWS_CLI=$(which aws)

if [ -z $AWS_CLI ];then
	apt-get update; apt install python-pip -y
	pip install awscli
fi

TOKEN=`curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"`
LOCAL_IP=`curl -H "X-aws-ec2-token: $TOKEN" -v http://169.254.169.254/latest/meta-data/local-ipv4`
BASE_DOMAIN=`aws route53 list-hosted-zones-by-name | grep $${ZONE_ID} -C 2 | grep -i name | awk -F":" '{print $2}' | awk -F"\"" '{print $2}'`

INDEX=0
DNS_NAME="$${ELASTIC_NAME}-$${INDEX}.$${BASE_DOMAIN::-1}"


cat > /tmp/elastic-record-set.json << EOF
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
aws route53 change-resource-record-sets --hosted-zone-id $${ZONE_ID} --change-batch file:///tmp/elastic-record-set.json
result=$?

until [ $result -eq 0 ];do
        INDEX=$(($INDEX + 1))
        DNS_NAME="$${ELASTIC_NAME}-$${INDEX}.$${BASE_DOMAIN::-1}"
cat > /tmp/elastic-record-set.json << EOF
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
aws route53 change-resource-record-sets --hosted-zone-id $${ZONE_ID} --change-batch file:///tmp/elastic-record-set.json 2>/dev/null 1>&2
result=$?
echo "DNS Record added with index: $${INDEX}"
done
hostnamectl set-hostname $${DNS_NAME}
sleep 20
sed -i "s/node.name: default/node.name: $${DNS_NAME}/; s/cluster.name: elk-acme/cluster.name: $${ELASTIC_NAME}/;" /etc/elasticsearch/elasticsearch.yml
sed -i "s/cluster.initial_master_nodes: elk01,elk02,elk03/cluster.initial_master_nodes: $${ELASTIC_NAME}-0.$${BASE_DOMAIN::-1},$${ELASTIC_NAME}-1.$${BASE_DOMAIN::-1},$${ELASTIC_NAME}-2.$${BASE_DOMAIN::-1}/" /etc/elasticsearch/elasticsearch.yml
sed -i "s/discovery.seed_hosts: elk01,elk02,elk03/discovery.seed_hosts: $${ELASTIC_NAME}-0.$${BASE_DOMAIN::-1},$${ELASTIC_NAME}-1.$${BASE_DOMAIN::-1},$${ELASTIC_NAME}-2.$${BASE_DOMAIN::-1}/" /etc/elasticsearch/elasticsearch.yml
echo 'node.master: true' >> /etc/elasticsearch/elasticsearch.yml
echo 'node.data: true' >> /etc/elasticsearch/elasticsearch.yml
echo "discovery.zen.ping.unicast.hosts: [\"$${ELASTIC_NAME}-0.$${BASE_DOMAIN::-1}\", \"$${ELASTIC_NAME}-1.$${BASE_DOMAIN::-1}\", \"$${ELASTIC_NAME}-2.$${BASE_DOMAIN::-1}\"]" >> /etc/elasticsearch/elasticsearch.yml

systemctl restart elasticsearch






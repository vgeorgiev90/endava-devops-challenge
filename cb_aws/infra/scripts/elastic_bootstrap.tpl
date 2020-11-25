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

mount_gp2_drive () {
local device_check=$(df -h |grep nvm | awk '{print $1}' |cut -c 6-12)
if [[ $device_check == "nvme1n1" ]];then
     added_dev="nvme0n1"
elif [[ $device_check == "nvme0n1" ]];then
     added_dev="nvme1n1"
fi
local fs_check=$(file -s /dev/$added_dev | awk '{print $2}')

if [[ $fs_check == "data" ]];then
    mkfs -t ext4 /dev/$added_dev
    mount /dev/$added_dev /var/lib/elasticsearch
fi

cp /etc/fstab /etc/fstab.orig
echo "/dev/$${added_dev} /var/lib/elasticsearch ext4 defaults,nofail  0  0" >> /etc/fstab
touch /var/lib/elasticsearch/migrated
}


if [ ! -f "/var/lib/elasticsearch/migrated" ];then
        mount_gp2_drive
        chown -R elasticsearch: /var/lib/elasticsearch
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
echo y | /usr/share/elasticsearch/bin/elasticsearch-plugin install discovery-ec2
sed -i "s/__NODE_NAME__/$${DNS_NAME}/; s/__CLUSTER_NAME__/$${ELASTIC_NAME}/; s/__TAG__/$${ELASTIC_NAME}/" /etc/elasticsearch/elasticsearch.yml
echo "cluster.initial_master_nodes: [\"$${ELASTIC_NAME}-0.$${BASE_DOMAIN::-1}\", \"$${ELASTIC_NAME}-1.$${BASE_DOMAIN::-1}\", \"$${ELASTIC_NAME}-2.$${BASE_DOMAIN::-1}\"]" >> /etc/elasticsearch/elasticsearch.yml


rm /var/lib/elasticsearch/* -rf

systemctl enable elasticsearch
systemctl restart elasticsearch






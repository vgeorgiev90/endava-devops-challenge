#!/bin/bash
## Automated deployment for the project ,as well as inventory files tracking.


############## Functions start #######################

#### Image build function ####

function image_build() {
        image="${1}"
        name=$(echo $image | awk -F"-" '{print $1}')
        tag=$(echo $image | awk -F"-" '{print $2}')
	read -p "Branch to build: " BRANCH
	read -p "Bitbucket username: " USER
	read -s -p "Bitbucket password: " PASS
        case ${name} in
                'webapp')
                        cd images/webapp
                        ${PACKER} build -var "tag=${tag}" -var "username=${USER}" -var "password=${PASS}" -var "branch=${BRANCH}" webapp-image.json
                        ;;
                'daemons')
                        cd images/daemons
                        ${PACKER} build -var "tag=${tag}" -var "username=${USER}" -var "password=${PASS}" -var "branch=${BRANCH}" daemons-image.json
                        ;;
                'base')
                        cd images/base
                        ${PACKER} build -var "tag=${tag}" base-image.json
                        ;;
                *)
                        echo "Please provide valid tag in form: NAME-VERSION"
                        echo "Example: webapp-v1, daemons-v1, base-v1"
        esac
}

#### Check if packer is installed ####
function check_packer() {

PACKER_URL="https://releases.hashicorp.com/packer/1.4.2/packer_1.4.2_linux_amd64.zip"
WGET=$(which wget)
UNZIP=$(which unzip)

PACKER=$(which packer)

if [ -z ${PACKER} ];then
        ${WGET} $PACKER_URL -P /root
        ${UNZIP} /root/packer_1.4.2_linux_amd64.zip -d /usr/local/bin
fi

}


function config_files() {
        if [ ! -d "deployments" ];then
                mkdir deployments
        fi

        deployment="${1}"
        if [ ! -d "deployments/${deployment}" ];then
                mkdir deployments/${deployment}
                cat > deployments/${deployment}/hosts << EOF
## Example hosts file , modify accordingly
# All servers on which the project will be deployed
[all]
#server1
#server2
#etc..
localhost

# Server for the webapp and socket daemon
[webapp]
localhost

# Server for queue worker daemon
[queue]
localhost

# Server for scheduler daemon
[scheduler]
localhost

# Server for support services (mysql, redis)
[support]
localhost
EOF

                cat > deployments/${deployment}/vars.json << EOF
{
   "registry_user": "registry-username",
   "registry_pass": "registry-password",
   "webapp_image": "fiftysaas/thetool-app:webapp-v1",
   "websocket_image": "fiftysaas/thetool-app:daemons-v1",
   "scheduler_image": "fiftysaas/thetool-app:daemons-v1",
   "queue_image": "fiftysaas/thetool-app:daemons-v1",
   "env": "default",
   "app_http_port": 80,
   "app_https_port": 443,
   "mysql_host_port": 3306,
   "redis_host_port": 6379,
   "domain": "viktor-prod.mysite.test",
   "app_logo": "MyApp",
   "app_name": "TheTool",
   "app_key": "base64:eIimjpvLX7G88kPqB1WnMPxXbTbqzN4LeNo7qxHManI=",
   "app_url": "http://12.34.56.78",
   "debug": true,
   "mail_host": "localhost",
   "mail_port": 25,
   "mail_username": null,
   "mail_password": null,
   "mail_encryption": null,
   "pusher_app_id": "myappid",
   "pusher_app_key": "myappidkey",
   "pusher_app_secret": "myappsecret",
   "pusher_app_cluster": "mt1",
   "pusher_app_scheme": "http",
   "filestack_key": null,
   "filestack_secret": null,
   "aws_key_id": null,
   "aws_key_secret": null,
   "aws_region": null,
   "aws_s3_bucket": null,
   "db_host": "172.31.16.114",
   "db_name": "app",
   "db_user": "app",
   "db_pass": "app123",
   "redis_host": "172.31.16.114",
   "websocket_address": "12.34.56.78",
   "websocket_port": 8100,
   "mysql_root_password": "viktor123",
   "mysql_database": "app",
   "mysql_user": "app",
   "mysql_password": "app123",
   "letsencrypt_mail_address": "someone@example.tld"
}
EOF
	clear
        echo "Sample variables and hosts file have been created in ./deployments/${deployment} directory."
        echo "Substitute all values as needed."
	echo ""
fi


}


function check_ansible() {
        ANSIBLE=$(which ansible)
        if [ -z ${ANSIBLE} ];then
                echo "ansible is not installed on the system , install it and run the script again."
                echo ""
                echo "https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html"
                exit
        fi
}


##################### Functions end ############################



##################### Scrit start ##############################

CHOICE="${1}"

case ${CHOICE} in
        'image-build')
                check_packer
                IMAGE="${2:-"generic-v1"}"
                image_build ${IMAGE}
                ;;
        'deploy')
                DEPLOYMENT="${2:-"base"}"
                config_files $DEPLOYMENT
		echo ""
                check_ansible
                read -n 1 -s -r -p "Press Enter to deploy , or press CTRL + C to exit..."
                echo ""
                read -p "Deploy support services(redis,mysql) yes/no: " SUPPORT
                if [ ${SUPPORT} == 'yes' ];then
                        ansible-playbook -i deployments/${DEPLOYMENT}/hosts ansible-deploy/playbook.yml --extra-vars "@deployments/${DEPLOYMENT}/vars.json"
                elif [ ${SUPPORT} == 'no' ];then
                        ansible-playbook -i deployments/${DEPLOYMENT}/hosts ansible-deploy/playbook.yml --extra-vars "@deployments/${DEPLOYMENT}/vars.json" --skip-tags=support
                else
                        echo "yes or no"
                fi
                ;;
        'update')
                DEPLOYMENT="${2:-"base"}"
                check_ansible
                if [ $DEPLOYMENT == "base" ];then
                        echo "Provide valid deployment name or create a new one.."
                        exit
                fi
		clear
                read -n 1 -s -r -p "Press Enter to deploy , or precc CTRL + C to exit..."
                ansible-playbook -i deployments/${DEPLOYMENT}/hosts ansible-deploy/playbook.yml --extra-vars "@deployments/${DEPLOYMENT}/vars.json" --skip-tags=support,init,certs
                ;;
        *)
                clear
                echo "Usage:"
                echo "=============================================="
                echo "Build images: ./manage.sh image-build NAME-TAG"
                echo "Example:"
                echo "./manage.sh image-build webapp-v1"
                echo "----------------------------------------------"
                echo "Deploy project: ./manage.sh deploy NAME"
                echo "Example:"
                echo "./manage.sh deploy prod"
                echo "----------------------------------------------"
                echo "Update deployment: ./manage.sh update NAME"
                echo "Example:"
                echo "./manage.sh update prod"
                ;;
esac

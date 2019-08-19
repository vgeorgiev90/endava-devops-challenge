### Playbook is for Ubuntu 18 , if other distributions will be included it needs to be changed a little bit.


Clone the repository
Use manage.sh script for image builds and deployments


All images will be pushed to fiftysaas/thetool-app registry in docker hub


Notes on deployment:

* Install Ansible on the host which will run deployment
* Generate ssh key for the root user and distribute it on all machines which will hold the infrastructure for the root user
* ssh-keygen

either:
* ssh-copy-id root@server(1,2,3, etc.)
or manual:
* cat /root/.ssh/id.rsa.pub  -- copy the content
* ssh root@my-server
* vim /root/.ssh/authorized_keys -- paste the public key

Clone the repository
* Run manage.sh deploy ENV - to generate hosts and variables files under environments directory
* Modify all values as needed and run - manage.sh deploy ENV to provision the environment


Release new version:
* run manage.sh deploy ENV to generate vars
* after all var values are changed as needed run it again to deploy
* When changes to the code are pushed in the repo build images with new versions.
* Make changes to vars.json/images part in the variable file for the env you want updated.
* Run manage.sh update ENV


Notes on manual deployment(without manage.sh script):
There are role tags included in the playbook so every component can either skipped from deployment or deployed single
Examples:
1. Deploy all without supporting services (mysql, redis)
* ansible-playbook -i hosts playbook.yml --skip-tags=support

2. Redeploy all webapp components , but keep existing .env file and support services
* ansible-playbook -i hosts playbook.yml --skip-tags=prereqs,support

3. Deploy only support services
* ansible-playbook -i hosts playbook.yml --tags=support

4. Deploy only webapp etc..
* ansible-playbook -i hosts playbook.yml --tags=webapp


Deployment roles overview:
  1. prerequesites 
     * Installs python-pip 
     * Installs docker-py module for ansible
     * Add docker repository
     * Installs docker-ce latest version
     * Create /etc/thetool directory and place .env template for mounting in the containers
  2. Support services
     * Create docker volumes for redis and mysql containers
     * Deploy mysql container and create database, user and password
     * Deploy redis container
  3. Deploy queue
     * Deploy queue worker container
  4. Deploy scheduler
     * Deploy scheduler container
  5. Deploy webapp
     * Deploy websocket container
     * Deploy webapp container and perform some initializations in the container(npm run prod, php artisan migrate)




TODO:
* Create terraform script for cloud provided infrastructure provisioning.                                                                  -- Discuss with Mert
* Create development environment provisioning with docker-compose or use existing one                                                      -- Discuss with Mert

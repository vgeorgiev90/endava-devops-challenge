# Endava Devops Challenge

## Task description
1) Fork this repository
2) Choose a free Cloud Service Provider and register a free account with AWS, Azure, etc. or run VirtualBox/VMware Player locally
3) Provision an Application stack running Apache Mysql PHP, each of the service must run separately on a node - virtual machine or container 
4) Automate the provisioning with the tools you like to use - bash, puppet, chef, Ansible, etc.
5) Implement service monitoring either using free Cloud Service provider monitoring or Datadog, Zabbix, Nagios, etc.
6) Automate service-fail-over, e.g. auto-restart of failing service
7) Document the steps in git history and commit your code
8) Present a working solution, e.g. not a powerpoint presentation, but a working demo

## Time Box 
The task should be completed within 5 days. 


## Solution
1) Terraform deployed infrastructure that consist of VPC, Subnet, Internet GW , 2 Security groups, 3 EC2 nodes
2) For the application stack the infrastructure choosen is kubernetes cluster deployed with systemd services rather than kubeadm , it is deployed with ansible playbook as well as most of the configuration
3) The application consist of: mysql container , nginx and php containers which hosts wordpress installation.
4) Monitoring solutions: Weave scope application which is part monitoring part utility , prometheus-grafana stack for detailed monitoring, kubernetes dashboard for ease of management.
5) Service fail-over is achieved with the kubernetes api , as well as with pod disruption budged.

Architecture:
This example solution is configured and provisions only 3 nodes , however the terraform and ansible are made to be scalable and can work with any number of nodes.
Instance type choosen is not eligible for aws free tier (t2.medium)

Workflow:
1. Configure AWS-cli and install terraform, ansible
2. Add all needed variables in terraform.tfvars file
3. Provision the infrastructure with terraform apply, after this is done note the output as it will be needed
4. Because of the OS choosen is ubuntu 18 and the way that AWS launches the instances prevent package installation user-data run support/get-python.sh script so python can be installed
4. With the output from terraform add all needed information in the hosts file for deploy-systemd-cluster ansible playbook (if the values are not supplied correctly there will be problems with the cluster deployment)
5. Login to the master node: 
  - label the master node with app=heketi 
  - change cluster_size to the worker node count
  - deploy heketi pod
  - after this is done run /root/post-install/deploy.sh get-key (this is the public key which needs to be added to authorized_keys file for the root user on every worker node)
  - exec into the container and change node* and device accordingly in /etc/heketi/topology.json
    sed -i 's/node1/10.100.1.14/g' topology.json
    sed -i 's/node2/10.100.1.120/g' topology.json
    sed -i 's/\/dev\/vdb/\/dev\/xvdf/g' topology.json
  - load the topology file: heketi-cli topology load --json=/etc/heketi/topology.json.
  - After this is done execute heketi-cli cluster list and note down the cluster id
6. Modify the file /root/post-install/storage-class.yml 
- change the resturl to http://MASTER-PRIVATE-IP:31000 ,cluster id and replication number 
- create the storage class and then patch it to become the default storageclass for the cluster
(kubectl patch storageclass glusterfs -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}')
7. Application can be deployed now with /root/post-install/deploy.sh deploy-app

Optional:
- Change the ingress node port service ports to be http - 80, https - 443 instead of random high number ports


Notes:
URLS (no external DNS): 
- weave scope app: http://weave.cluster
- monitoring: http://grafana.cluster
- dashboard: http://dashboard.cluster
default credentials (not for dashboard of course)
- user: admin
- password: admin123
- Virtual host for the wordpress app: 
- http://endava.example.site  - (there is no DNS so it should be pointed to one of the public IPs localy)

Things that needs to be done manually (for the moment)
- modify your ansible hosts file
- bootstrap glusterfs cluster with heketi

TODO:
- Add metrics server and Horizontal pod autoscalling for the app
- Automate glusterfs clustering
- Automate the transition from terraform to ansible.
- Maybe refine a thing or two :)

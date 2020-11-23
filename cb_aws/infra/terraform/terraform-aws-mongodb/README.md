# This module is to be used to deploy MongoDB replication cluster with autoscalling group.

Resources included:
* AWS IAM role for Route53 DNS management
* AWS Launch Configuration for MongoDB cluster
* AWS Autoscaling group for MongoDB cluster
* AWS AutoScaling Policy
* AWS CloudWatch metric to trigger the autoscaling policy based on CPU usage.


Variables explanation:
ami_owner              --> type = string                        -->  AWS AMI Owner ID
vpc_id                 --> type = string                        -->  VPC where the resources will be deployed ( Check the tagging requirements if you deploy to your own vpc )
private_zone_id        --> type = string                        -->  Route53 private zone ID for the DNS records
name_prefix            --> type = string, default = "staging"   -->  Name prefix to be used for resource tagging and DNS name creation (Keep consistent).
mongo_instance_type    --> type = string, default = "t3.small"  -->  Instance type for MongoDB
ssh_key_pair           --> type = string                        -->  SSH key pair to be used for the instances ( Name of the existing ssh key pair )
security_group_id      --> type = string                        -->  Security group for the instances (Use the generic group created with the VPC module, or make sure traffic from the VPC cidr is allowed)
mongo_volume_size      --> type = number, default = 30          -->  Disk space size for the instances ( GB )
mongo_max_instances    --> type = number, default = 5           -->  Maximum number of instances for the AG group
mongo_min_instances    --> type = number, default = 3           -->  Desired number of instances ( keep default )
mongo_root_password    --> type = string                        -->  Root password for mongodb ( Check the image build ansible playbook )


Notes:
1. MongoDB cluster is bootstraped with scripts/mongo_bootstrap.tpl, it depends on private DNS records.
2. Every node's hostname is based on the DNS record that will be used, it consists of: mongo_name( name_prefix + '-mongo'), index(0,1,2...), base_domain(extracted from route53 with the private_zone_id), example: staging-elastic-0.internal.aws.cobrowser.io
3. Resources deployment depends on the unique subnet tagging
4. Cluster is initialized with 1 master and 2 replicas if the number needs to change the deployment script needs to be modified too.



TODO:
Add dynamic self-healing for the mongodb cluster ( based on AWS lambda )



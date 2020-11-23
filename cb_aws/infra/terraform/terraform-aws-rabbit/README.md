# This module is to be used to deploy RabbitMQ cluster with autoscalling group.

Resources included:
* AWS IAM role for Route53 DNS management
* AWS Launch Configuration for RabbitMQ cluster
* AWS Autoscaling group for RabbitMQ cluster
* AWS AutoScaling Policy
* AWS CloudWatch metric to trigger the autoscaling policy based on CPU usage.


Variables explanation:
* ami_owner             -->  type = string                        -->  AWS AMI Owner ID
* vpc_id                -->  type = string                        -->  VPC where the resources will be deployed ( Check the tagging requirements if you deploy to your own vpc )
* private_zone_id       -->  type = string                        --> Route53 private zone ID for the DNS records
* name_prefix           -->  type = string, default = "staging"   --> Name prefix to be used for resource tagging and DNS name creation (Keep consistent).
* rabbit_instance_type  -->  type = string, default = "t3.small"  --> Instance type for RabbitMQ
* ssh_key_pair          -->  type = string                        --> SSH key pair to be used for the instances ( Name of the existing ssh key pair )
* security_group_id     -->  type = string                        -->  Security group for the instances (Use the generic group created with the VPC module, or make sure traffic from the VPC cidr is allowed)
* rabbit_volume_size    -->  type = number, default = 30          -->  Disk space size for the instances ( GB )
* rabbit_max_instances  -->  type = number, default = 5           -->  Maximum number of instances for the AG group
* rabbit_min_instances  -->  type = number, default = 3           -->  Desired number of instances ( keep default )



Notes:
1. RabbitMQ cluster is bootstraped with scripts/rabbit_bootstrap.tpl, it depends on private DNS records.
2. Every node's hostname is based on the DNS record that will be used, it consists of: rabbit_name( name_prefix + 'rabbit'), index(0,1,2...), base_domain(extracted from route53 with the private_zone_id), example: staging-rabbit-0.internal.aws.cobrowser.io
3. Resources deployment depends on the unique subnet tagging



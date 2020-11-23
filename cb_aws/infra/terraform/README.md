# This repo holds all aws infrastructure needed for CB aws migration, splited in TF modules

* terraform-aws-vpc           -->  Module for VPC creation based on AWS best practices.
* terraform-aws-management    -->  Module for CB management instances
* terraform-aws-eks           -->  Module for EKS cluster deployment
* terraform-aws-elastic       -->  Module for Elasticsearch cluster deployment
* terraform-aws-rabbit        -->  Module for RabbitMQ cluster deployment
* terraform-aws-mongodb       -->  Module for MongoDB replication cluster deployment
* terraform-aws-vpc-peerings  -->  Module for VPC peerings deployment

Refer to the differnt modules readme file for details.


General dependencies:
1. AWS Route53 Public Zone    -->  aws.cobrowser.io
2. AWS Route53 Private Zone   -->  internal.aws.cobrowser.io


Notes:
This modules are designed to work with CB images only

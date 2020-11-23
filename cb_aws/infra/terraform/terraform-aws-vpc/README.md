# This module is to be used for VPC deployment based on AWS best practice.

Resources included:
* Internet gateway
* NAT gateway
* 3 Public Subnets
* 3 Private Subnets
* 3 DB Private Subnets
* 3 ES Private Subnets
* 3 RMQ Private Subnets
* 2 Route tables
* Route table associations
* Generic Security Group to be used for all instances


Variables explanation:

vpc_cidr             -> type = string, default = "192.168.0.0/16"                                        --> CIDR block for the VPC
public_subnet_cidrs  -> type = list, default = ["192.168.1.0/24", "192.168.2.0/24", "192.168.3.0/24"]    --> CIDR blocks for the public subnets
private_subnet_cidrs -> type = list, default = ["192.168.4.0/24", "192.168.5.0/24", "192.168.6.0/24"]    --> CIDR blocks for the private subnets
db_subnet_cidrs      -> type = list, default = ["192.168.7.0/24", "192.168.8.0/24", "192.168.9.0/24"]    --> CIDR blocks for the MongoDB subnets
rmq_subnet_cidrs     -> type = list, default = ["192.168.10.0/24", "192.168.11.0/24", "192.168.12.0/24"] --> CIDR blocks for the RMQ subnets
es_subnet_cidrs      -> type = list, default = ["192.168.13.0/24", "192.168.14.0/24", "192.168.15.0/24"] --> CIDR blocks for the Elastic subnets
name_prefix          -> type = string, default = "Staging"                                               --> Name prefix for almost all resources that will be created ( keep this consistent in all modules )
public_count         -> type = number, default = 3                                                       --> How many public subnets do we want
private_count        -> type = number, default = 3                                                       --> How many private subnets do we want
db_private_count     -> type = number, default = 3                                                       --> How many database private subnets do we want
es_private_count     -> type = number, default = 3                                                       --> How many elastic private subnets do we want
rmq_private_count    -> type = number, default = 3                                                       --> How many rabbitmq private subnets do we want



Notes:
1. All count variables are used to specify how many subnets are needed and also to control if any subnets should be created (Example: we want management VPC with only one public and one private subnet all we need to do is to specify 1 for public and private and 0 for all others)

2. If the number of subnets is changed, also change the subnet CIDRs (example: we need just 1 public subnet, so public_subnet_cidrs will equal to ["192.168.1.0/24"])

3. IMPORTANT: All subnets are uniquely tagged so other resources can be deployed.



TODO:
Include Network Access Control List for all subnets to restrict traffic flow.

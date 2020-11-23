# This module is to be used to deploy EKS cluster with worker node group inside autoscaling group.

Resources included:
* AWS IAM role for EKS
* AWS IAM role for worker nodes
* EKS cluster
* Worker node group inside autoscaling

Variables explanation:
vpc_id                  --> type = string                         -->  VPC where the resources will be deployed ( Check the tagging requirements if you deploy to your own vpc )
name_prefix             --> type = string, default = "staging"    -->  Name prefix to be used for resource tagging and DNS name creation (Keep consistent).
eks_version             --> type = string, default = "1.17"       -->  Kubernetes control plane version (Check the AWS supported versions if you want to change)
cluster_security_group  --> type = string                         -->  Securituy group for the cluster ( Use the generic that was created with the VPC )
eks_nodes_disk_size     --> type = number, default = 30           -->  Disk size for worker nodes
eks_nodes_instance_type --> type = string, default = "t3.medium"  -->  Instance type for the worker nodes
ssh_key                 --> type = string                         -->  SSH key name for worker nodes access
eks_desired_size        --> type = number, default = 3            -->  Desired worker nodes count
eks_min_size            -->  type = number, default = 3           -->  Min worker nodes count
eks_max_size            -->  type = number, default = 5           -->  Max worker nodes count




Notes:
1. EKS Control plane is deployed in 3 public and 3 private subnets so public facing load balancers can be provisioned.
2. Worker nodes are deployed only in 3 private subnets.
3. If you are to use your own VPC/Subnets check the EKS vpc tagging requirements.

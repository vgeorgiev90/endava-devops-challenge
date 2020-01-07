## Example EKS CF template deployed with sceptre wrapper
#Includes
- VPC
- 3 Subnets . 1 public, 2 private
- Bastion host
- EKS control plane
- Worker node group
- Security groups for bastion and EKS

Dependencies:
sceptre

Ref: https://github.com/Sceptre/sceptre

Usage:
Change all variables in config/dev as needed
deploy -> sceptre create dev

Further sceptre documentation:
https://sceptre.cloudreach.com/latest/docs/get_started.html

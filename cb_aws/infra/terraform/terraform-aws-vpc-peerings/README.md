# This module is to be used for VPC peerings deployment.

Resources included:
* VPC peering connection
* Route tables route adjustment


Variables explanation:
* peer_vpc_id  -->  type = string                         -->  ID of the vpc peer
* vpc_id       -->  type = string                         -->  ID of the main vpc
* name_prefix  -->  type = string, default = "staging"    -->  Name prefix to be used for resource tagging and search (keep consistent.)



Notes:
1. This module creates the peering connection between 2 VPCs in the same account.
2. It modifies the existing route tables for these VPCs to include the new route.
3. It is to be used only for VPC that are created with the vpc module (It requires uniqe subnet tagging)



# This module is to be used to deploy CB management stack (vpn server, build server, security monitoring server).

Resources included:
* VPN Server
* Build Server
* Security server
* VPN Security group
* Load balancer for the VPN server (to be used for VPN traffic and external SSH connections)
* Load balancer for the Security server (OSSEC dashborad, to be extended)
* Route53 Public DNS record for vpn
* Route53 Private DNS record for build server
* Route53 Private DNS record for Security server 

Variables explanation:
ami_owner 		   -->  type = string                         -->  AWS AMI Owner ID
generic_security_group_id  -->  type = string                         -->  Security group to be used for the instances (generic group that was created with the VPC)
vpn_instance_type          -->  type = string, default = "t3.medium"  -->  Instance type for the VPN
security_instance_type     -->  type = string, default = "t3.medium"  --> Instance type for the security server
build_instance_type        -->  type = string, default = "t3.medium"  --> Instance type for the build server
ssh_key_pair               -->  type = string                         --> SSH key name for the instances
vpc_id 			   -->  type = string                         --> VPC where the resources will be deployed ( Check the tagging requirements if you deploy to your own vpc )
vpn_port 		   -->  type = number, default = 61443        -->  Port number for the VPN ( no need to change )
vpn_protocol  	 	   -->  type = string, default = "UDP"        --> Protocol for the VPN ( no need to change )
route53_public_zone_id     -->  type = string                         -->  Route53 public zone ID for the DNS records
route53_private_zone_id    -->  type = string                         -->  Route53 private zone ID for the DNS records
record_name                -->  type = string, default = "vpn.aws.cobrowser.io"            -->  DNS Record for the vpn ( no need to change if the same zone will be used)
ossec_record_name          -->  type = string, default = "ossec.internal.aws.cobrowser.io" --> DNS record for the OSSEC dashboard (no need to change)
build_record_name          -->  type = string, default = "build.internal.aws.cobrowser.io" --> DNS record for the build server
ssh_allowed_ips            -->  type = list                           --> List of IPs to allow for SSH access (["1.2.3.4/32", "5.6.7.8/32"])



Notes:
1. VPN Server is based on WireGuard, it comes with a user management script
2. OSSEC agent is installed by default on all machines that will be deployed, after the ossec server is created manual adding of the ossec agents will be needed.






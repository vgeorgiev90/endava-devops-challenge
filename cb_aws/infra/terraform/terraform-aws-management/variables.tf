variable "ami_owner" {
	type = string
}

variable "generic_security_group_id" {
	type = string
	description = "ID of the generic security group that was created with the vpc"
}

variable "vpn_instance_type" {
	type = string
	default = "t3.medium"
}

variable "security_instance_type" {
	type = string
	default = "t3.medium"
}

variable "build_instance_type" {
	type = string
	default = "t3.medium"
}

variable "ssh_key_pair" {
	type = string
}

variable "vpc_id" {
	type = string
}

variable "region" {
	type = string
	default = "eu-west-1"
}

variable "vpn_port" {
	type = number
	default = 61443
}

variable "vpn_protocol" {
	type = string
	default = "UDP"
}

variable "route53_public_zone_id" {
	type = string
	description = "Route53 Public Zone"
}

variable "route53_private_zone_id" {
	type = string
	description = "Route53 Private Zone"
}

variable "record_name" {
	type = string
	default = "vpn.aws.cobrowser.io"
}

variable "ossec_record_name" {
	type = string
	default = "ossec.internal.aws.cobrowser.io"
}

variable "build_record_name" {
	type = string
	default = "build.internal.aws.cobrowser.io"
}

variable "ssh_allowed_ips" {
	type = list
        description = "IPs to whitelist for SSH access in CIDR format: 1.2.3.4/32"
}

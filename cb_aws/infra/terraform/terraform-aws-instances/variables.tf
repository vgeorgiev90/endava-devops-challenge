variable "ami_owner" {
	type = string
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

variable "route53_zone_id" {
	type = string
}

variable "record_name" {
	type = string
	default = "vpn.aws.cobrowser.io"
}

variable "ssh_allowed_ips" {
	type = list
        description = "IPs to whitelist for SSH access in CIDR format: 1.2.3.4/32"
}

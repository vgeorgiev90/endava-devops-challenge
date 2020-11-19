variable "ami_owner" {
	type = string
}

variable "vpn_instance_type" {
	type = string
}

variable "ssh_key_pair" {
	type = string
}

variable "vpn_subnet_id" {
	type = string
}

variable "vpc_id" {
	type = string
}

variable "vpc_cidr" {
	type = string
}

variable "subnets_public" {
	type = list
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
}

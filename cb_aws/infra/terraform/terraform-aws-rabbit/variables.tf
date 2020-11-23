variable "region" {
	type = string
	default = "eu-west-1"
}

variable "ami_owner" {
	type = string
}

variable "vpc_id" {
	type = string
}

variable "private_zone_id" {
	type = string
}

variable "name_prefix" {
	type = string
	default = "staging"
}

variable "rabbit_instance_type" {
	type = string
	default = "t3.small"
}

variable "ssh_key_pair" {
	type = string
}

variable "security_group_id" {
	type = string
}

variable "rabbit_volume_size" {
	type = number
	default = 30
}

variable "rabbit_max_instances" {
	type = number
	default = 5
}

variable "rabbit_min_instances" {
	type = number
	default = 3
}

variable "region" {
	type = string
	default = "eu-west-1"
}

variable "peer_vpc_id" {
	type = string
}

variable "vpc_id" {
	type = string
}

variable "name_prefix" {
	type = string
	default = "staging"
}

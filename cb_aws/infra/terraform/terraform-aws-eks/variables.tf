variable "region" {
	type = string
	default = "eu-west-1"
}
variable "vpc_id" {
	type = string
}
variable "name_prefix" {
	type = string
	default = "testing"
}
variable "eks_version" {
	type = string
	default = "1.17"
}
variable "cluster_security_group" {
	type = list
}
variable "eks_nodes_disk_size" {
	type = number
	default = 30
}
variable "eks_nodes_instance_type" {
	type = list
}
variable "ssh_key" {
	type = string
}
variable "eks_desired_size" {
	type = number
	default = 1
}
variable "eks_min_size" {
	type = number
	default = 1
}
variable "eks_max_size" {
	type = number
	default = 1
}


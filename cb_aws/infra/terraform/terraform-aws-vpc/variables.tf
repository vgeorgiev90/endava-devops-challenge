variable "vpc_cidr" {
  type = string
  default = "192.168.0.0/16"
}

variable "public_subnet_cidrs" {
  type = list
  default = ["192.168.1.0/24", "192.168.2.0/24", "192.168.3.0/24"]
}

variable "private_subnet_cidrs" {
  type = list
  default = ["192.168.4.0/24", "192.168.5.0/24", "192.168.6.0/24"]
}

variable "db_subnet_cidrs" {
  type = list
  default = ["192.168.7.0/24", "192.168.8.0/24", "192.168.9.0/24"]
} 

variable "rmq_subnet_cidrs" {
  type = list
  default = ["192.168.10.0/24", "192.168.11.0/24", "192.168.12.0/24"]
}

variable "es_subnet_cidrs" {
  type = list
  default = ["192.168.13.0/24", "192.168.14.0/24", "192.168.15.0/24"]
}

variable "name_prefix" {
  type = string
  default = "Staging"
}

variable "region" {
  type = string
  default = "eu-west-1"
}

variable "public_count" {
  type = number
  default = 3
}

variable "private_count" {
  type = number
  default = 3
}

variable "db_private_count" {
  type = number
  default = 3
}

variable "es_private_count" {
  type = number
  default = 3
}

variable "rmq_private_count" {
  type = number
  default = 3
}

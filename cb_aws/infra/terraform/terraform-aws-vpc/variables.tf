variable "vpc_cidr" {}

variable "public_subnet_cidrs" {
  type = list
}

variable "private_subnet_cidrs" {
  type = list
}

variable "db_subnet_cidrs" {
  type = list
} 

variable "rmq_subnet_cidrs" {
  type = list
}

variable "es_subnet_cidrs" {
  type = list
}

variable "region" {
  type = string
  default = "eu-west-1"
}

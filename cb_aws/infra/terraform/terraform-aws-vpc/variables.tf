variable "vpc_cidr" {
  type = string
}

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

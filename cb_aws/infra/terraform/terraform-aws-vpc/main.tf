provider "aws" {
  region = var.region
}

## Declare the VPC resources

#################### Get availability zones ##########

data "aws_availability_zones" "available_zones" {}

###################### VPC creation ##################

resource "aws_vpc" "cb_vpc" {
  cidr_block = var.vpc_cidr
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.name_prefix} VPC"
  }
}

###################### Public subnet definitions ########################

resource "aws_subnet" "public" {
  count = var.public_count
  vpc_id = aws_vpc.cb_vpc.id
  cidr_block = var.public_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available_zones.names[count.index]

  tags = {
    Name = "${var.name_prefix} public subnet"
    Tier = "Public"
  }
}


###################### Private subnets for EKS #####################

resource "aws_subnet" "private" {
  count = var.private_count
  vpc_id = aws_vpc.cb_vpc.id
  cidr_block = var.private_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available_zones.names[count.index]

  tags = {
    Name = "${var.name_prefix} private subnet"
    Tier = "Private"
  }
}

################### Private subnets for services #############

resource "aws_subnet" "db_private" {
  count = var.db_private_count
  vpc_id = aws_vpc.cb_vpc.id
  cidr_block = var.db_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available_zones.names[count.index]

  tags = {
    Name = "${var.name_prefix} database subnet"
    Tier = "Private"
    Apps = "DB"
  }
}

resource "aws_subnet" "elastic_private" {
  count = var.es_private_count
  vpc_id = aws_vpc.cb_vpc.id
  cidr_block = var.es_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available_zones.names[count.index]

  tags = {
    Name = "${var.name_prefix} elastic subnet"
    Tier = "Private"
    Apps = "ElasticSearch"
  }
}

resource "aws_subnet" "rmq_private" {
  count = var.rmq_private_count
  vpc_id = aws_vpc.cb_vpc.id
  cidr_block = var.rmq_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available_zones.names[count.index]

  tags = {
    Name = "${var.name_prefix} RMQ subnet"
    Tier = "Private"
    Apps = "RMQ"
  }
}
#################### Internet Gateway #################

resource "aws_internet_gateway" "cb_gw" {
  vpc_id = aws_vpc.cb_vpc.id
}

################### Elastic Ip for nat gateway ###########
resource "aws_eip" "nat" {
  vpc = true
}

################### Nat gateway ###########################
data "aws_subnet_ids" "public_subs" {
  vpc_id = aws_vpc.cb_vpc.id
  tags = {
    Tier = "Public"
  }
  depends_on = [aws_vpc.cb_vpc, aws_subnet.public]
}

resource "random_shuffle" "nat_subnet" {
  input = data.aws_subnet_ids.public_subs.ids
  result_count = 1
}

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat.id
  subnet_id     = random_shuffle.nat_subnet.result.0
  depends_on = [aws_internet_gateway.cb_gw]

  tags = {
    Name = "${var.name_prefix} NAT_private_subnets"
  }
}

################ Route table definitions ####################

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.cb_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.cb_gw.id
  }

  tags = {
    Name = "${var.name_prefix} Public route table"
  }
}

resource "aws_route_table_association" "public_association" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public.*.id[count.index]
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.cb_vpc.id
 
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id  
  }

  tags = {
    Name = "${var.name_prefix} Private route table"
  }
}

resource "aws_route_table_association" "private_association" {
  count = length(aws_subnet.private)
  subnet_id = aws_subnet.private.*.id[count.index]
  route_table_id  = aws_route_table.private.id
}

resource "aws_route_table_association" "db_private_association" {
  count = length(aws_subnet.db_private)
  subnet_id = aws_subnet.db_private.*.id[count.index]
  route_table_id  = aws_route_table.private.id
}

resource "aws_route_table_association" "rmq_private_association" {
  count = length(aws_subnet.rmq_private)
  subnet_id = aws_subnet.rmq_private.*.id[count.index]
  route_table_id  = aws_route_table.private.id
}

resource "aws_route_table_association" "es_private_association" {
  count = length(aws_subnet.elastic_private)
  subnet_id = aws_subnet.elastic_private.*.id[count.index]
  route_table_id  = aws_route_table.private.id
}


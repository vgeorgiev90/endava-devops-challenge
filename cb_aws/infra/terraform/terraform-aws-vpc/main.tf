provider "aws" {
  region = var.region
}

## Declare the VPC resources

#################### Get availability zones ##########

data "aws_availability_zones" "available_zones" {}

###################### VPC creation ##################

resource "aws_vpc" "cb_vpc" {
  cidr_block = "${var.vpc_cidr}"
  enable_dns_support = true
  enable_dns_hostnames = true

  tags {
    Name = "Staging VPC"
  }
}

###################### Public subnet definitions ########################

resource "aws_subnet" "public" {
  count = 2
  vpc_id = "${aws_vpc.cb_vpc.id}"
  cidr_block = "${var.public_subnet_cidrs[count.index]}"
  availability_zone = "${data.aws_availability_zones.available_zones.names[count.index]}" 

  tags {
    Name = "Staging public subnet"
  }
}


###################### Private subnets for EKS #####################

resource "aws_subnet" "private" {
  count = 2
  vpc_id = "${aws_vpc.cb_vpc.id}"
  cidr_block = "${var.private_subnet_cidrs[count.index]}"
  availability_zone = "${data.aws_availability_zones.available_zones.names[count.index]}"

  tags {
    Name = "Staging private subnet"
  }
}

################### Private subnets for services #############

resource "aws_subnet" "db_private" {
  count = 2
  vpc_id = "${aws_vpc.cb_vpc.id}"
  cidr_block = "${var.db_subnet_cidrs[count.index]}"
  availability_zone = "${data.aws_availability_zones.available_zones.names[count.index]}"

  tags {
    Name = "database subnet"
  }
}

resource "aws_subnet" "elastic_private" {
  count = 2
  vpc_id = "${aws_vpc.cb_vpc.id}"
  cidr_block = "${var.es_subnet_cidrs[count.index]}"
  availability_zone = "${data.aws_availability_zones.available_zones.names[count.index]}"

  tags {
    Name = "elastic subnet"
  }
}

resource "aws_subnet" "rmq_private" {
  count = 2
  vpc_id = "${aws_vpc.cb_vpc.id}"
  cidr_block = "${var.rmq_subnet_cidrs[count.index]}"
  availability_zone = "${data.aws_availability_zones.available_zones.names[count.index]}"

  tags {
    Name = "RMQ subnet"
  }
}
#################### Internet Gateway #################

resource "aws_internet_gateway" "cb_gw" {
  vpc_id = "${aws_vpc.cb_vpc.id}"
}

################ Route table definitions ####################

resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.cb_vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.cb_gw.id}"
  }

  tags {
    Name = "Public route table"
  }
}

resource "aws_route_table_association" "public_association" {
  count          = "${aws_subnet.public.count}"
  subnet_id      = "${aws_subnet.public.*.id[count.index]}"
  route_table_id = "${aws_route_table.public.id}"
}

resource "aws_route_table" "private" {
  vpc_id = "${aws_vpc.cb_vpc.id}"

  tags {
    Name = "Private route table"
  }
}

resource "aws_route_table_association" "private_association" {
  count = "${aws_subnet.private.count}"
  subnet_id = "${aws_subnet.private.*.id[count.index]}"
  route_table_id  = "${aws_route_table.private.id}"
}

resource "aws_route_table_association" "db_private_association" {
  count = "${aws_subnet.db_private.count}"
  subnet_id = "${aws_subnet.db_private.*.id[count.index]}"
  route_table_id  = "${aws_route_table.private.id}"
}

resource "aws_route_table_association" "rmq_private_association" {
  count = "${aws_subnet.rmq_private.count}"
  subnet_id = "${aws_subnet.rmq_private.*.id[count.index]}"
  route_table_id  = "${aws_route_table.private.id}"
}

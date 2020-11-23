provider "aws" {
  region = var.region
}

################### Route table data ##########################
data "aws_vpc" "one_cidr" {
  id = var.vpc_id
}

data "aws_vpc" "two_cidr" {
  id = var.peer_vpc_id
}

data "aws_subnet_ids" "public_vpc_one" {
  vpc_id = var.vpc_id
  tags = {
    Tier = "Public"
  }
}

resource "random_shuffle" "pub_subnet1" {
  input = data.aws_subnet_ids.public_vpc_one.ids
  result_count = 1
}

data "aws_subnet_ids" "private_vpc_one" {
  vpc_id = var.vpc_id
  tags = {
    Tier = "Private"
  }
}

resource "random_shuffle" "priv_subnet1" {
  input = data.aws_subnet_ids.private_vpc_one.ids
  result_count = 1
}


data "aws_subnet_ids" "public_vpc_two" {
  vpc_id = var.peer_vpc_id
  tags = {
    Tier = "Public"
  }
}

resource "random_shuffle" "pub_subnet2" {
  input = data.aws_subnet_ids.public_vpc_two.ids
  result_count = 1
}

data "aws_subnet_ids" "private_vpc_two" {
  vpc_id = var.peer_vpc_id
  tags = {
    Tier = "Private"
  }
}

resource "random_shuffle" "priv_subnet2" {
  input = data.aws_subnet_ids.private_vpc_two.ids
  result_count = 1
}


##############################################################

resource "aws_vpc_peering_connection" "peering" {
  peer_vpc_id   = var.peer_vpc_id
  vpc_id        = var.vpc_id
  auto_accept   = true

  accepter {
    allow_remote_vpc_dns_resolution = true
  }

  requester {
    allow_remote_vpc_dns_resolution = true
  }

  tags = {
    Name = "${var.name_prefix}-peering"
  }
}


################# Route tables update #########################

data "aws_route_table" "vpc_one_rt1" {
  subnet_id = random_shuffle.pub_subnet1.result.0
}

data "aws_route_table" "vpc_one_rt2" {
  subnet_id = random_shuffle.priv_subnet1.result.0
}

data "aws_route_table" "vpc_two_rt1" {
  subnet_id = random_shuffle.pub_subnet2.result.0
}

data "aws_route_table" "vpc_two_rt2" {
  subnet_id = random_shuffle.priv_subnet2.result.0
}


resource "aws_route" "route1" {
  route_table_id            = data.aws_route_table.vpc_one_rt1.id
  destination_cidr_block    = data.aws_vpc.two_cidr.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peering.id
  depends_on = [aws_vpc_peering_connection.peering]
}

resource "aws_route" "route2" {
  route_table_id            = data.aws_route_table.vpc_one_rt2.id
  destination_cidr_block    = data.aws_vpc.two_cidr.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peering.id
  depends_on = [aws_vpc_peering_connection.peering]
}


resource "aws_route" "route3" {
  route_table_id            = data.aws_route_table.vpc_two_rt1.id
  destination_cidr_block    = data.aws_vpc.one_cidr.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peering.id
  depends_on = [aws_vpc_peering_connection.peering]
}

resource "aws_route" "route4" {
  route_table_id            = data.aws_route_table.vpc_two_rt2.id
  destination_cidr_block    = data.aws_vpc.one_cidr.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peering.id
  depends_on = [aws_vpc_peering_connection.peering]
}


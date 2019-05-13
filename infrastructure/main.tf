## Declare the VPC resources

provider "aws" {
  region = "${var.region}"
}

locals {
  instance-userdata = <<EOF
#!/bin/bash
export PATH=$PATH:/usr/local/bin
sleep 60
apt-get install python-minimal -y
EOF
}


###################### VPC creation ##################

resource "aws_vpc" "cluster_vpc" {
  cidr_block = "${var.vpc_cidr}"
  enable_dns_support = true
  enable_dns_hostnames = true

  tags {
    Name = "Terraform endava VPC"
  }
}

###################### Public subnet definitions ########################

resource "aws_subnet" "public" {
  vpc_id = "${aws_vpc.cluster_vpc.id}"
  cidr_block = "${var.subnet_cidr}"
  availability_zone = "${var.availability_zone}"

  tags {
    Name = "Cluster public subnet"
  }
}

#################### Internet Gateway #################

resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.cluster_vpc.id}"
}

################ Route table definitions ####################

resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.cluster_vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }

  tags {
    Name = "Public route table"
  }
}

resource "aws_route_table_association" "public_association" {
  subnet_id      = "${aws_subnet.public.id}"
  route_table_id = "${aws_route_table.public.id}"
}


########## Security groups definitions ################

resource "aws_security_group" "cluster_sg" {
  name = "Cluster-security-group"
  description = "Security group for cluster communications"
  vpc_id = "${aws_vpc.cluster_vpc.id}"

  ingress {
   from_port = 0
   to_port = 0
   protocol = "-1"
   cidr_blocks = ["${var.vpc_cidr}"]
  }

  ingress {
   from_port = 0
   to_port = 0
   protocol = "-1"
   cidr_blocks = ["${var.access_ip}"]
  }

  egress {
   from_port       = 0
   to_port         = 0
   protocol        = "-1"
   cidr_blocks     = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "public_sg" {
  name = "Public-security-group"
  description = "Security group for external communications"
  vpc_id = "${aws_vpc.cluster_vpc.id}"

  ingress {
   from_port = 80
   to_port = 80
   protocol = "tcp"
   cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
   from_port = 443
   to_port = 443
   protocol = "tcp"
   cidr_blocks = ["0.0.0.0/0"]
  }


  egress {
   from_port       = 0
   to_port         = 0
   protocol        = "-1"
   cidr_blocks     = ["0.0.0.0/0"]
  }
}

####################### EC2 RESOURCES ###########################

###### Create Key pair for ansible usage #####

resource "aws_key_pair" "ssh_key_pair" {
  key_name = "${var.key_name}"
  public_key = "${file(var.public_key_path)}"
}


##### Get AMI data ########

data "aws_ami" "cluster" {
  most_recent = true
  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }
  owners = ["amazon"]
  filter {
    name   = "name"
    values = ["ubuntu-bionic-18.04-*"]
  }
}


############ Instances ##################

resource "aws_instance" "master" {
  depends_on = ["aws_subnet.public"]
  ami = "${data.aws_ami.cluster.id}"
  instance_type = "${var.instance_type}"
  key_name               = "${aws_key_pair.ssh_key_pair.id}"
  vpc_security_group_ids = ["${aws_security_group.cluster_sg.id}", "${aws_security_group.public_sg.id}"]
  subnet_id              = "${aws_subnet.public.id}"
  associate_public_ip_address = true
  user_data_base64 = "${base64encode(local.instance-userdata)}"
  tags {
    Name = "Master Node"
  }
}

resource "aws_instance" "worker" {
  count = "${var.count}"
  depends_on = ["aws_subnet.public"]
  ami = "${data.aws_ami.cluster.id}"
  instance_type = "${var.instance_type}"
  key_name               = "${aws_key_pair.ssh_key_pair.id}"
  vpc_security_group_ids = ["${aws_security_group.cluster_sg.id}", "${aws_security_group.public_sg.id}"]
  subnet_id              = "${aws_subnet.public.id}"
  associate_public_ip_address = true
  user_data_base64 = "${base64encode(local.instance-userdata)}"
  ebs_block_device {
        device_name = "/dev/xvdf"
        volume_type = "gp2"
        volume_size = "20"
  }
  tags {
    Name = "Worker-${count.index}"
  }
}



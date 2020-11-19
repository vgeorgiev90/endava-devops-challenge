provider "aws" {
  region = var.region
}

############# Wireguard instance definition #############

data "aws_ami" "vpn_server" {
  most_recent = true
  owners = [var.ami_owner]
  filter {
    name   = "name"
    values = ["wireguard-ubuntu20-*"]
  }
}

resource "aws_instance" "vpn_server" {
  ami 				  = data.aws_ami.vpn_server.id
  instance_type 		  = var.vpn_instance_type
  key_name               	  = var.ssh_key_pair
  vpc_security_group_ids 	  = [ aws_security_group.generic.id ]
  subnet_id              	  = var.vpn_subnet_id
  associate_public_ip_address = false
  tags = {
    Name = "Wireguard VPN"
  }
}

resource "aws_security_group" "generic" {
  name        = "Generic"
  description = "Genric group for all instances"
  vpc_id      = var.vpc_id

  ingress {
    description = "VPC traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Generic"
  }
}

############# Vpn Load balancer #################

resource "aws_lb" "vpn" {
  name               = "VpnLoadBalancer"
  internal           = false
  load_balancer_type = "network"
  subnets            = var.subnets_public

  enable_cross_zone_load_balancing = true
  tags = {
    Name = "VPN-LB"
  }
}

############ LB Listeners #################
resource "aws_lb_listener" "vpn_listener" {
  load_balancer_arn = aws_lb.vpn.arn
  port              = var.vpn_port
  protocol          = var.vpn_protocol

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.vpn_instance.arn
  }
  depends_on = [ aws_lb_target_group.vpn_instance ]
}

resource "aws_lb_listener" "ssh_listener" {
  load_balancer_arn = aws_lb.vpn.arn
  port              = "22"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.vpn_instance_ssh.arn
  }
  depends_on = [ aws_lb_target_group.vpn_instance_ssh ]
}
############ VPN LB Target Group ###############
resource "aws_lb_target_group" "vpn_instance" {
  name     = "WireguardGroup"
  port     = var.vpn_port
  protocol = var.vpn_protocol
  vpc_id   = var.vpc_id
  target_type = "instance"
 
  health_check {
    protocol = "TCP"
    port = 22
  }

  tags = {
    Name = "Wireguard-TG"
  }
}

resource "aws_lb_target_group" "vpn_instance_ssh" {
  name     = "WireguardGroupSsh"
  port     = "22"
  protocol = "TCP"
  vpc_id   = var.vpc_id
  target_type = "instance"
  
  health_check {
    protocol = "TCP"
    port = 22
  }

  tags = {
    Name = "Wireguard-TG-SSH"
  }
}

resource "aws_alb_target_group_attachment" "wireguard" {
  target_group_arn = aws_lb_target_group.vpn_instance.arn
  target_id        = aws_instance.vpn_server.id 
}

resource "aws_alb_target_group_attachment" "wireguard_ssh" {
  target_group_arn = aws_lb_target_group.vpn_instance_ssh.arn
  target_id        = aws_instance.vpn_server.id 
}


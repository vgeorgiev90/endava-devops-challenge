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

data "aws_vpc" "deploy" {
  id = var.vpc_id
}

data "aws_subnet_ids" "public" {
  vpc_id = var.vpc_id
  tags = {
    Tier = "Public"
  }
}

resource "random_shuffle" "vpn_subnet" {
  input = data.aws_subnet_ids.public.ids
  result_count = 1
}

locals {
  subnet_list = tolist(data.aws_subnet_ids.public.ids)
  
}

################ Security Host ##########################
data "aws_ami" "security_server" {
  most_recent = true
  owners = [var.ami_owner]
  filter {
    name   = "name"
    values = ["security-ubuntu20-*"]
  }
}

resource "aws_instance" "security_server" {
  ami                             = data.aws_ami.security_server.id
  instance_type                   = var.security_instance_type
  key_name                        = var.ssh_key_pair
  vpc_security_group_ids          = [ var.generic_security_group_id ]
  subnet_id                       = random_shuffle.vpn_subnet.result.0
  associate_public_ip_address = false
  tags = {
    Name = "OSSEC Server"
  }
}


################ Build Server ###########################
data "aws_ami" "build_server" {
  most_recent = true
  owners = [var.ami_owner]
  filter {
    name   = "name"
    values = ["build-ubuntu20-*"]
  }
}

resource "aws_instance" "build_server" {
  ami                             = data.aws_ami.build_server.id
  instance_type                   = var.build_instance_type
  key_name                        = var.ssh_key_pair
  vpc_security_group_ids          = [ var.generic_security_group_id ]
  subnet_id                       = random_shuffle.vpn_subnet.result.0
  associate_public_ip_address = false
  tags = {
    Name = "BuildServer"
  }
}


################ VPN Server ##############################

resource "aws_instance" "vpn_server" {
  ami 				  = data.aws_ami.vpn_server.id
  instance_type 		  = var.vpn_instance_type
  key_name               	  = var.ssh_key_pair
  vpc_security_group_ids 	  = [ aws_security_group.vpn.id ]
  subnet_id              	  = random_shuffle.vpn_subnet.result.0
  associate_public_ip_address = false
  tags = {
    Name = "Wireguard VPN"
  }
}


resource "aws_security_group" "vpn" {
  name        = "WireguardVpn"
  description = "Security group for the AWS VPN"
  vpc_id      = var.vpc_id

  ingress {
    description = "VPC traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [ data.aws_vpc.deploy.cidr_block ]
  }

  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_allowed_ips
  }

  ingress {
    description = "VPN access"
    from_port   = 61443
    to_port     = 61443
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
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
  subnets            = local.subnet_list

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

############## Security LB ############################

resource "aws_lb" "security" {
  name               = "OSSECLoadBalancer"
  internal           = true
  subnets            = local.subnet_list

  enable_cross_zone_load_balancing = true
  tags = {
    Name = "Ossec-LB"
  }
}

############ OSSEC LB Listeners #################
resource "aws_lb_listener" "security_listener" {
  load_balancer_arn = aws_lb.security.arn
  port              = 80
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.security_instance.arn
  }
  depends_on = [ aws_lb_target_group.security_instance ]
}

############ OSSEC LB Target Group ###############
resource "aws_lb_target_group" "security_instance" {
  name     = "SecurityServerTargetGroup"
  port     = 80
  protocol = "TCP"
  vpc_id   = var.vpc_id
  target_type = "instance"

  health_check {
    protocol = "HTTP"
    port = 80
  }

  tags = {
    Name = "Security-TG"
  }
}


resource "aws_alb_target_group_attachment" "security" {
  target_group_arn = aws_lb_target_group.security_instance.arn
  target_id        = aws_instance.security_server.id
}



############## Route53 Records #########################

resource "aws_route53_record" "wireguard" {
  zone_id = var.route53_zone_id
  name    = var.record_name
  type    = "A"
  alias {
    name                   = aws_lb.vpn.dns_name
    zone_id                = aws_lb.vpn.zone_id
    evaluate_target_health = false
  }
  depends_on = [aws_lb.vpn]
}

resource "aws_route53_record" "ossec" {
  zone_id = var.route53_zone_id
  name    = var.ossec_record_name
  type    = "A"
  alias {
    name                   = aws_lb.security.dns_name
    zone_id                = aws_lb.security.zone_id
    evaluate_target_health = false
  }
  depends_on = [aws_lb.security]
}

resource "aws_route53_record" "build" {
  zone_id = var.route53_zone_id
  name    = var.build_record_name
  type    = "A"
  ttl     = "300"
  records = [aws_instance.build_server.private_ip]
}

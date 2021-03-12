provider "aws" {
  region = var.region
}

######################## AWS IAM instance profile for route53 management #######################

resource "aws_iam_instance_profile" "route53_profile" {
  name = "route53_profile_es"
  role = aws_iam_role.route53_role.name
}

resource "aws_iam_role_policy" "route53_policy" {
  name = "route53_policy_es"
  role = aws_iam_role.route53_role.id
 
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
     {
       "Effect": "Allow",
       "Action": "route53:*",
       "Resource": "*"
     }
  ]
}
EOF
}

################ EC2 Describe policy for elasticsearch auto cluster discovery #####

resource "aws_iam_role_policy" "ec2describe_policy" {
  name = "ec2describe_policy_es"
  role = aws_iam_role.route53_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
     {
       "Effect": "Allow",
       "Action": "ec2:DescribeInstances",
       "Resource": "*"
     }
  ]
}
EOF
}

resource "aws_iam_role" "route53_role" {
  name = "route53_role_es"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}




################################### Rabbitmq cluster aws data ###############################


data "aws_ami" "elastic_ami" {
  most_recent = true
  owners = [var.ami_owner]
  filter {
    name   = "name"
    values = ["elasticsearch-ubuntu18-*"]
  }
}

data "aws_subnet_ids" "es_private" {
  vpc_id = var.vpc_id
  tags = {
    Tier = "Private"
    Apps = "ElasticSearch"
  }
}

locals {
  es_subnet_list = tolist(data.aws_subnet_ids.es_private.ids)
}


############################### RMQ Launch config ############################

resource "aws_launch_configuration" "elastic_config" {
  name_prefix = "${var.name_prefix}-elasticsearch"
  #image_id = data.aws_ami.elastic_ami.id
  image_id = "ami-027957ea28be834cd"
  instance_type = var.elastic_instance_type
  key_name = var.ssh_key_pair
  security_groups = [ var.security_group_id ]
  associate_public_ip_address = false
  ebs_optimized = false
  iam_instance_profile = aws_iam_instance_profile.route53_profile.id
  user_data_base64 = base64encode(templatefile("../../scripts/elastic_bootstrap.tpl", {zone = var.private_zone_id, env = var.name_prefix}))
  root_block_device {
    volume_type = "gp2"
    volume_size = 20
  }
  
  ebs_block_device {
    device_name = "/dev/sdf"
    volume_type = "gp2"
    volume_size = var.elastic_volume_size
    delete_on_termination = false
  }

  lifecycle {
    create_before_destroy = true
  }
}

############################ RMQ Autoscaling group ###########################

resource "aws_autoscaling_group" "elastic_ag" {
  vpc_zone_identifier = local.es_subnet_list
  max_size = var.elastic_max_instances
  min_size = var.elastic_min_instances
  health_check_type = "EC2"
  health_check_grace_period = 900
  enabled_metrics = ["GroupMinSize", "GroupMaxSize", "GroupDesiredCapacity", "GroupInServiceInstances", "GroupTotalInstances"]
  metrics_granularity = "1Minute"
  launch_configuration = aws_launch_configuration.elastic_config.name

  tags = [{
    key = "Name"
    value = "${var.name_prefix}-elastic"
    propagate_at_launch = true
  },
  {
    key = "application"
    value = "elasticsearch"
    propagate_at_launch = true
  },
  {
    key = "ec2discovery"
    value = "${var.name_prefix}-elastic"
    propagate_at_launch = true
  }]

  lifecycle {
    create_before_destroy = true
  }
}

########### Autoscaling policies ################

resource "aws_autoscaling_policy" "as_policy" {
  name = "${var.name_prefix}-elastic-as-policy"
  autoscaling_group_name = aws_autoscaling_group.elastic_ag.name
  adjustment_type = "ChangeInCapacity"
  scaling_adjustment = "1"
  cooldown = 300
}

##### Cloud watch alarms for scale up #########

resource "aws_cloudwatch_metric_alarm" "scale_up" {
  alarm_name = "${var.name_prefix}-elastic-cpu-scale-up"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = "3"
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  period = "120"
  statistic = "Average"
  threshold = "95"
  dimensions = {
    "AutoScalingGroupName" = aws_autoscaling_group.elastic_ag.name
  }
  actions_enabled = true
  alarm_actions = [aws_autoscaling_policy.as_policy.arn]
}


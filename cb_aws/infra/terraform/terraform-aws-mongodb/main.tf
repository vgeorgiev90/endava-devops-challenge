provider "aws" {
  region = var.region
}

######################## AWS IAM instance profile for route53 management #######################

resource "aws_iam_instance_profile" "route53_profile_db" {
  name = "route53_profile_db"
  role = aws_iam_role.route53_role.name
}

resource "aws_iam_role_policy" "route53_policy" {
  name = "route53_policy_db"
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


resource "aws_iam_role" "route53_role" {
  name = "route53_role_db"
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


data "aws_ami" "mongo_ami" {
  most_recent = true
  owners = [var.ami_owner]
  filter {
    name   = "name"
    values = ["mongodb-ubuntu18-*"]
  }
}

data "aws_subnet_ids" "db_private" {
  vpc_id = var.vpc_id
  tags = {
    Tier = "Private"
    Apps = "DB"
  }
}

locals {
  db_subnet_list = tolist(data.aws_subnet_ids.db_private.ids)
}


############################### RMQ Launch config ############################

resource "aws_launch_configuration" "mongo_config" {
  name_prefix = "${var.name_prefix}-mongo"
  image_id = data.aws_ami.mongo_ami.id
  instance_type = var.mongo_instance_type
  key_name = var.ssh_key_pair
  security_groups = [ var.security_group_id ]
  associate_public_ip_address = false
  ebs_optimized = false
  iam_instance_profile = aws_iam_instance_profile.route53_profile_db.id
  user_data_base64 = base64encode(templatefile("../../scripts/mongo_bootstrap.tpl", {zone = var.private_zone_id, env = var.name_prefix, mongo_admin_pass = var.mongo_root_password}))
  root_block_device {
    volume_type = "gp2"
    volume_size = var.mongo_volume_size
  }
}

############################ RMQ Autoscaling group ###########################

resource "aws_autoscaling_group" "mongo_ag" {
  vpc_zone_identifier = local.db_subnet_list
  max_size = var.mongo_max_instances
  min_size = var.mongo_min_instances
  health_check_type = "EC2"
  health_check_grace_period = 900
  enabled_metrics = ["GroupMinSize", "GroupMaxSize", "GroupDesiredCapacity", "GroupInServiceInstances", "GroupTotalInstances"]
  metrics_granularity = "1Minute"
  launch_configuration = aws_launch_configuration.mongo_config.name

  tags = [{
    key = "Name"
    value = "${var.name_prefix}-mongo"
    propagate_at_launch = true
  },
  {
    key = "application"
    value = "mongodb"
    propagate_at_launch = true
  }]

}

########### Autoscaling policies ################

resource "aws_autoscaling_policy" "as_policy" {
  name = "${var.name_prefix}-mongo-as-policy"
  autoscaling_group_name = aws_autoscaling_group.mongo_ag.name
  adjustment_type = "ChangeInCapacity"
  scaling_adjustment = "1"
  cooldown = 300
}

##### Cloud watch alarms for scale up #########

resource "aws_cloudwatch_metric_alarm" "scale_up" {
  alarm_name = "${var.name_prefix}-mongo-cpu-scale-up"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = "3"
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  period = "120"
  statistic = "Average"
  threshold = "95"
  dimensions = {
    "AutoScalingGroupName" = aws_autoscaling_group.mongo_ag.name
  }
  actions_enabled = true
  alarm_actions = [aws_autoscaling_policy.as_policy.arn]
}


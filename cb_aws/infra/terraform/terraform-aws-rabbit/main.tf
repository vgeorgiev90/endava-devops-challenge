provider "aws" {
  region = var.region
}

######################## AWS IAM instance profile for route53 management #######################

resource "aws_iam_instance_profile" "route53_profile" {
  name = "route53_profile"
  role = aws_iam_role.route53_role.name
}

resource "aws_iam_role_policy" "route53_policy" {
  name = "route53_policy"
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
  name = "route53_role"
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


data "aws_ami" "rabbit_ami" {
  most_recent = true
  owners = [var.ami_owner]
  filter {
    name   = "name"
    values = ["rabbitmq-ubuntu18-*"]
  }
}

data "aws_subnet_ids" "rmq_private" {
  vpc_id = var.vpc_id
  tags = {
    Tier = "Private"
    Apps = "RMQ"
  }
}

locals {
  rmq_subnet_list = tolist(data.aws_subnet_ids.rmq_private.ids)
  instance_userdata = <<EOF
#!/bin/bash

ZONE_ID="${var.zone_id}"
ENV="${var.name_prefix}"

RABBIT_NAME=${ENV}-rabbit
AWS_CLI=$(which aws)

if [ -z $AWS_CLI ];then
        apt-get update; apt install python-pip -y
        pip install awscli
fi

TOKEN=`curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"`
LOCAL_IP=$(curl -H "X-aws-ec2-token: $TOKEN" -v http://169.254.169.254/latest/meta-data/local-ipv4)
INDEX=$(curl -H "X-aws-ec2-token: $TOKEN" -v http://169.254.169.254/latest/meta-data/ami-launch-index)
DNS_NAME="${RABBIT_NAME}${INDEX}.aws.cobrowser.io"

cat > /tmp/rabbit-record-set.json << EOF
                {
                  "Comment": "RabbitMQ Node: ${INDEX}",
                  "Changes": [{
                        "Action": "CREATE",
                        "ResourceRecordSet": {
                            "Name": "${DNS_NAME}",
                            "Type": "A",
                            "ResourceRecords": [{ "Value": "${LOCAL_IP}"}]
                              }
                          }]
                }
EOF
aws route53 change-resource-record-sets --hosted-zone-id ${ZONE_ID} --change-batch file:///tmp/rabbit-record-set.json
EOF
}

############################### RMQ Launch config ############################

resource "aws_launch_configuration" "rabbit_config" {
  name_prefix = "${var.name_prefix}-rabbit"
  image_id = data.aws_ami.rabbit_ami.id
  instance_type = var.rabbit_instance_type
  key_name = var.ssh_key_pair
  security_groups = [ var.security_group_id ]
  associate_public_ip_address = false
  ebs_optimized = false
  user_data = file("userdata")
  iam_instance_profile = aws_iam_instance_profile.route53_profile.id
  user_data_base64 = base64encode(local.instance_userdata)
  root_block_device {
    volume_type = "gp2"
    volume_size = var.rabbit_volume_size
  }
}

############################ RMQ Autoscaling group ###########################

resource "aws_autoscaling_group" "rabbit_ag" {
  vpc_zone_identifier = local.rmq_subnet_list
  max_size = var.rabbit_max_instances
  min_size = var.rabbit_min_instances
  health_check_type = "EC2"
  health_check_grace_period = 900
  enabled_metrics = ["GroupMinSize", "GroupMaxSize", "GroupDesiredCapacity", "GroupInServiceInstances", "GroupTotalInstances"]
  metrics_granularity = "1Minute"
  launch_configuration = aws_launch_configuration.rabbit_config.name

  tags = {
    Name = "${var.name_prefix}-rabbit"
    propagate_at_launch = true
  }
}

########### Autoscaling policies ################

resource "aws_autoscaling_policy" "as_policy" {
  name = "${var.name_prefix}-rabbit-as-policy"
  autoscaling_group_name = aws_autoscaling_group.rabbit_ag.name
  adjustment_type = "ChangeInCapacity"
  scaling_adjustment = "1"
  cooldown = 300
}

##### Cloud watch alarms for scale up #########

resource "aws_cloudwatch_metric_alarm" "scale_up" {
  alarm_name = "${var.name_prefix}-rabbit-cpu-scale-up"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = "3"
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  period = "120"
  statistic = "Average"
  threshold = "95"
  dimensions = {
    "AutoScalingGroupName" = aws_autoscaling_group.rabbit_ag.name
  }
  actions_enabled = true
  alarm_actions = [aws_autoscaling_policy.as_policy.arn]
}


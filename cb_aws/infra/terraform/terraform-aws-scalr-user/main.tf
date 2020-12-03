provider "aws" {
	region = var.region
}


############## User declaration ##################

resource "aws_iam_user" "scalr" {
	name = "scalr_provisioner"
	
	tags = {
		Name = "scalr_provisioner"
	}
}

resource "aws_iam_access_key" "scalr" {
	user = aws_iam_user.scalr.name
}

############# IAM Policies for the user ##############


resource "aws_iam_user_policy" "scalr_ec2" {
  name = "scalr_ec2"
  user = aws_iam_user.scalr.name

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Stmt1606734486356",
      "Action": "ec2:*",
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Sid": "Stmt1606734498617",
      "Action": "autoscaling:*",
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Sid": "Stmt1606734515808",
      "Action": "elasticloadbalancing:*",
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Sid": "Stmt1606734559485",
      "Action": "iam:*",
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Sid": "Stmt1606734618113",
      "Action": "eks:*",
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Sid": "Stmt1606734721249",
      "Action": "route53:*",
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}



provider "aws" {
    region = var.region
}


################# Subnet data for EKS ########################

data "aws_subnet_ids" "eks_private" {
  vpc_id = var.vpc_id
  tags = {
    Tier = "Private"
  }
}

data "aws_subnet_ids" "eks_public" {
  vpc_id = var.vpc_id
  tags = {
    Tier = "Public"
  }
}


locals {
  private_subnet_list = tolist(data.aws_subnet_ids.eks_private.ids)
  public_subnet_list = tolist(data.aws_subnet_ids.eks_public.ids)
  all_subnets = tolist(data.aws_subnet_ids.eks_private.ids, data.aws_subnet_ids.eks_public.ids)
}


##################### IAM Policies ############################

resource "aws_iam_role" "eks" {
  name = "${var.name_prefix}-eks-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "eksClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks.name
}

resource "aws_iam_role_policy_attachment" "eksVpcResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks.name
}


resource "aws_iam_role" "eksNodes" {
  name = "${var.name_prefix}-eksNodes"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "eksWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eksNodes.name
}

resource "aws_iam_role_policy_attachment" "eksCNIPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eksNodes.name
}

resource "aws_iam_role_policy_attachment" "eksEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eksNodes.name
}


####################### EKS Cluster #########################

resource "aws_eks_cluster" "eksCluster" {
  name     = "${var.name_prefix}-eks"
  role_arn = aws_iam_role.eks.arn
  version = var.eks_version
  vpc_config {
    subnet_ids = local.all_subnets
    security_group_ids = var.cluster_security_group
  }

  depends_on = [
    aws_iam_role_policy_attachment.eksClusterPolicy,
    aws_iam_role_policy_attachment.eksVpcResourceController
  ]
}


##################### EKS Node Group ########################

resource "aws_eks_node_group" "example" {
  cluster_name = "${var.name_prefix}-eks"  
  node_group_name = "${var.name_prefix}-eks-nodegroup"
  node_role_arn = aws_iam_role.eksNodes.arn
  subnet_ids = local.private_subnet_list
  disk_size = var.eks_nodes_disk_size
  instance_types = var.eks_nodes_instance_type
  
  remote_access {
    eks_ssh_key = var.ssh_key
    source_security_group_ids = var.cluster_security_group
  }

  scaling_config {
    desired_size = var.eks_desired_size
    min_size = var.eks_min_size
    max_size = var.eks_max_size
  }

  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }

  depends_on = [aws_eks_cluster.eksCluster]
  tags {
    Name = "${var.name_prefix}-eks-node"
  }
}

variable "project" {}

variable "env" {}

variable "region" {}

provider "aws" {
  region = var.region
}
# Latest 외 사용 시 AMI 활용하기
#data "aws_ssm_parameter" "ami" {
#  name = "/aws/service/eks/optimized-ami/1.23/amazon-linux-2/recommended/image_id"
#}
resource "aws_iam_role" "cluster" {
  name               = "${var.project}-${var.env}-cluster"
  assume_role_policy = <<-ASSUME_ROLE_POLICY
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
  ASSUME_ROLE_POLICY

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
  ]
  tags = {
    "Name"    = "${var.project}-${var.env}-cluster"
    "cluster" = "${var.project}-${var.env}"
    "Owner"   = "parrotbill"
  }
}
resource "aws_iam_role" "node" {
  name               = "${var.project}-${var.env}-node"
  assume_role_policy = <<-ASSUME_ROLE_POLICY
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "ec2.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
  }
  ASSUME_ROLE_POLICY

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
  ]
  tags = {
    "Name"    = "${var.project}-${var.env}-node"
    "cluster" = "${var.project}-${var.env}"
    "Owner"   = "parrotbill"
  }
}
resource "aws_iam_instance_profile" "node" {
  name = "${var.project}-${var.env}-node"
  role = aws_iam_role.node.name
  tags = {
    "Owner"   = "parrotbill"
  }
}
resource "aws_security_group" "default-vpc-peering" {
  name   = "${var.project}-${var.env}-default-vpc-peering"
  vpc_id = data.terraform_remote_state.network.outputs.vpc_id
  ingress = [
    {
      cidr_blocks      = []
      description      = "default-vpc peering"
      from_port        = 0
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      protocol         = "-1"
      security_groups = [
        "sg-032270cddc9905baf",
      ]
      self    = false
      to_port = 0
    },
  ]
  tags = {
    "Name"    = "${var.project}-${var.env}-default-vpc-peering"
    "cluster" = "${var.project}-${var.env}"
    "Owner"   = "parrotbill"
  }
}
resource "aws_eks_cluster" "main" {
  name     = "${var.project}-${var.env}"
  role_arn = aws_iam_role.cluster.arn
  version  = "1.23"
#  kubernetes_network_config {
#    service_ipv4_cidr = "10.100.0.0/16"
#  }
  enabled_cluster_log_types = []
  vpc_config {
    subnet_ids = [
      data.terraform_remote_state.network.outputs.subnet_eu-west-1a_id,
      data.terraform_remote_state.network.outputs.subnet_eu-west-1b_id,
      data.terraform_remote_state.network.outputs.subnet_eu-west-1c_id
    ]
  }
  tags = {
    "cluster" = "${var.project}-${var.env}"
    "Owner"   = "parrotbill"
  }
}
resource "aws_iam_role" "aws_iam_role_node_group" {
  name = "${var.project}-node-group-role-${var.env}"
  assume_role_policy = jsonencode({
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }]
    Version = "2012-10-17"
  })
}
resource "aws_iam_role_policy" "node_auto_scaling" {
  name = "${var.project}-node-auto-scaling-policy-${var.env}"
  role = aws_iam_role.aws_iam_role_node_group.id
  policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "autoscaling:DescribeAutoScalingGroups",
                "autoscaling:DescribeAutoScalingInstances",
                "autoscaling:DescribeLaunchConfigurations",
                "autoscaling:DescribeTags",
                "autoscaling:SetDesiredCapacity",
                "autoscaling:TerminateInstanceInAutoScalingGroup",
                "ec2:DescribeLaunchTemplateVersions"
            ],
            "Resource": "*",
            "Effect": "Allow"
        }
    ]
  }
  EOF
}
resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role = aws_iam_role.aws_iam_role_node_group.name
}
resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role = aws_iam_role.aws_iam_role_node_group.name
}
resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role = aws_iam_role.aws_iam_role_node_group.name
}
resource "aws_iam_role_policy_attachment" "AmazonS3FullAccess" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  role = aws_iam_role.aws_iam_role_node_group.name
}
resource "aws_launch_template" "private" {
  name = "${var.project}-private"
  default_version = 1
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.project}-private"
      Owner = "parrotbill"
    }
  }
  key_name = "private-ng"
}
resource "aws_eks_node_group" "private" {
  cluster_name = aws_eks_cluster.main.name
  node_group_name = "${var.project}-private"
  node_role_arn = aws_iam_role.aws_iam_role_node_group.arn
  instance_types = ["t3.micro"]
  version = 1.23
  scaling_config {
    desired_size = 1
    max_size = 2
    min_size = 0
  }
  subnet_ids = [
    data.terraform_remote_state.network.outputs.subnet_eu-west-1c_id,
  ]
  labels = {
    env: "private"
  }
  launch_template {
    name = aws_launch_template.private.name
    version = aws_launch_template.private.default_version
  }
}
variable "project" {}

variable "env" {}

variable "region" {}

provider "aws" {
  region = var.region
}
data "aws_availability_zones" "aws_availability_zones" {
}
resource "aws_vpc" "main" {
  cidr_block = "172.31.0.0/16"
  tags = {
    "Name"    = "${var.project}-${var.env}"
    "cluster" = "${var.project}-${var.env}"
    "Owner"   = "parrotbill"
  }
}
resource "aws_subnet" "eu-west-1a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "172.31.16.0/20"
  availability_zone       = data.aws_availability_zones.aws_availability_zones.names[0]
  map_public_ip_on_launch = true
  tags = {
    "Name"    = "${var.project}-${var.env}-eu-west-1a"
    "cluster" = "${var.project}-${var.env}"
    "Owner"   = "parrotbill"
  }
}
resource "aws_subnet" "eu-west-1b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "172.31.32.0/20"
  availability_zone = data.aws_availability_zones.aws_availability_zones.names[0]
  tags = {
    "Name"    = "${var.project}-${var.env}-eu-west-1b"
    "cluster" = "${var.project}-${var.env}"
    "Owner"   = "parrotbill"
  }
}
resource "aws_subnet" "eu-west-1c" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "172.31.0.0/20"
  availability_zone = data.aws_availability_zones.aws_availability_zones.names[1]
  tags = {
    "Name"    = "${var.project}-${var.env}-eu-west-1c"
    "cluster" = "${var.project}-${var.env}"
    "Owner"   = "parrotbill"
  }
}
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    "Name"    = "${var.project}-${var.env}"
    "cluster" = "${var.project}-${var.env}"
    "Owner"   = "parrotbill"
  }
}
resource "aws_route_table" "rtb-09c54bb0bb94dabc8" {
  vpc_id = aws_vpc.main.id
  route = [
    {
      carrier_gateway_id         = ""
      cidr_block                 = "0.0.0.0/0"
      destination_prefix_list_id = ""
      egress_only_gateway_id     = ""
      gateway_id                 = aws_internet_gateway.main.id
      instance_id                = ""
      ipv6_cidr_block            = "::/0"
      local_gateway_id           = ""
      nat_gateway_id             = ""
      network_interface_id       = ""
      transit_gateway_id         = ""
      vpc_endpoint_id            = ""
      vpc_peering_connection_id  = ""
      core_network_arn           = null
    },
  ]
  tags = {
    "Name"    = "${var.project}-${var.env}-default"
    "cluster" = "${var.project}-${var.env}"
    "Owner"   = "parrotbill"
  }
}
resource "aws_route_table_association" "eu-west-1c" {
  subnet_id      = aws_subnet.eu-west-1c.id
  route_table_id = aws_route_table.rtb-09c54bb0bb94dabc8.id
  tags = {
    "Owner"   = "parrotbill"
  }
}
resource "aws_vpc_peering_connection" "default-vpc" {
  peer_owner_id = "576066064056"
  vpc_id        = aws_vpc.main.id
  peer_vpc_id   = "vpc-05a4d5a600c6d1c63"
  auto_accept   = true
  tags = {
    "Name"    = "${var.project}-${var.env}-to-default-vpc"
    "cluster" = "${var.project}-${var.env}"
    "Owner"   = "parrotbill"
  }
}
output "vpc_id" {
  value = aws_vpc.main.id
}
output "subnet_eu-west-1a_id" {
  value = aws_subnet.eu-west-1a.id
}
output "subnet_eu-west-1b_id" {
  value = aws_subnet.eu-west-1b.id
}
output "subnet_eu-west-1c_id" {
  value = aws_subnet.eu-west-1c.id
}
output "subnet_eu-west-1c_cidr_block" {
  value = aws_subnet.eu-west-1c.cidr_block
}
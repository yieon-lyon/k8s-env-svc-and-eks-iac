variable "project" {}

variable "env" {}

variable "region" {}

provider "aws" {
  region = var.region
}
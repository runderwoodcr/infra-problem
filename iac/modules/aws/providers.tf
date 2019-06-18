#
# Provider Configuration

provider "aws" {
  version = "~> 2.14"
  region = "${var.aws-region}"
}

provider "template" {
  version = "~> 2.1"
}

provider "random"{
  version = "~> 2.1"
}

provider "http" {
  version = "~> 1.1"
}

provider "null"{
  version = "~> 2.1"
}

data "aws_region" "current" {}

data "aws_availability_zones" "available" {}


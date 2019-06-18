# EKS Terraform module

module "aws" {
  source                = "./modules/aws"
  cluster-name          = "${var.cluster-name}"
  k8s-version           = "${var.k8s-version}"
  aws-region            = "${var.aws-region}"
  node-instance-type    = "${var.node-instance-type}"
  node-key              = "${var.node-key}"
  desired-capacity      = "${var.desired-capacity}"
  max-size              = "${var.max-size}"
  min-size              = "${var.min-size}"
  vpc-subnet-cidr       = "${var.vpc-subnet-cidr}"
  ecr-static            = "${var.ecr-static}"
  ecr-front-end         = "${var.ecr-front-end}"
  ecr-newsfeed          = "${var.ecr-newsfeed}"
  ecr-quotes            = "${var.ecr-quotes}"
  jenkins_instance_type = "${var.jenkins_instance_type}"
  repo_name             = "${var.repo_name}"
  repo_default_branch   = "${var.repo_default_branch}"
}

# Variables Configuration

variable "cluster-name" {
  default     = "infra-cluster"
  type        = "string"
  description = "The name of your EKS Cluster"
}

variable "aws-region" {
  default     = "us-east-1"
  type        = "string"
  description = "The AWS Region to deploy EKS"
}

variable "k8s-version" {
  default     = "1.12"
  type        = "string"
  description = "Required K8s version"
}

variable "vpc-subnet-cidr" {
  default     = "10.0.0.0/16"
  type        = "string"
  description = "The VPC Subnet CIDR"
}

variable "node-instance-type" {
  default     = "t3.xlarge"
  type        = "string"
  description = "Worker Node EC2 instance type"
}

variable "jenkins_instance_type" {
  default     = "t3.large"
  type        = "string"
  description = "Jenkins EC2 instance Type"
}

variable "node-key" {
  default     = "runderwood"
  type        = "string"
  description = "Key pair for EC2 instances"
}

variable "desired-capacity" {
  default     = 2
  type        = "string"
  description = "Autoscaling Desired node capacity"
}

variable "max-size" {
  default     = 5
  type        = "string"
  description = "Autoscaling maximum node capacity"
}

variable "min-size" {
  default     = 2
  type        = "string"
  description = "Autoscaling Minimum node capacity"
}

variable "ecr-static" {
  default     = "static-content"
  type        = "string"
  description = "Repository for Static Content"
}

variable "ecr-front-end" {
  default     = "frontend"
  type        = "string"
  description = "Repository for Front-End"
}

variable "ecr-newsfeed" {
  default     = "newsfeed"
  type        = "string"
  description = "Repository for News Feeds"
}

variable "ecr-quotes" {
  default     = "quotes"
  type        = "string"
  description = "Repository for Quotes"
}

variable "repo_name"{
  default     = "infra-problem"
  type        = "string"
  description = "Code Repository"
}

variable "repo_default_branch"{
  default     = "master"
  type        = "string"
  description = "Repository Default Branch"
}
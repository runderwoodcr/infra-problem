# ECR Resources

variable "ecr-static" {}
variable "ecr-front-end" {}
variable "ecr-newsfeed" {}
variable "ecr-quotes" {}


resource "aws_ecr_repository" "static_service" {
  name = "${var.ecr-static}"
} 

resource "aws_ecr_repository" "frontend_service" {
  name = "${var.ecr-front-end}"
} 

resource "aws_ecr_repository" "newsfeed_service" {
  name = "${var.ecr-newsfeed}"
} 

resource "aws_ecr_repository" "quotes_service" {
  name = "${var.ecr-quotes}"
} 
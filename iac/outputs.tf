output "kubeconfig" {
  value = "${module.aws.kubeconfig}"
}

output "config-map" {
  value = "${module.aws.config-map-aws-auth}"
}

output "static-repo" {
  value = "${module.aws.repository_url_static_service}"
}

output "frontend-repo" {
  value = "${module.aws.repository_url_frontend_service}"
}

output "newsfeed-repo" {
  value = "${module.aws.repository_url_newsfeed_service}"
}

output "quotes-repo" {
  value = "${module.aws.repository_url_quotes_service}"
}

output "repository_http_url"{
  value = "${module.aws.codecommit_repository_http_url}"
}

output "jenkins_public_ip"{
  value = "${module.aws.jenkins_IP}"
}

output "Jenkins_Password"{
  value = "${module.aws.jenkinsPassword}"
}

output "repository_name"{
  value = "${var.repo_name}"
}

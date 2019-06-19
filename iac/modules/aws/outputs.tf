#
# Outputs
#

locals {
  config-map-aws-auth = <<CONFIGMAPAWSAUTH

apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
    - rolearn: ${aws_iam_role.node.arn}
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes
    - rolearn: ${aws_iam_role.jenkins_role.arn}
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:masters
        - system:nodes
CONFIGMAPAWSAUTH

  kubeconfig = <<KUBECONFIG

apiVersion: v1
clusters:
- cluster:
    server: ${aws_eks_cluster.eks.endpoint}
    certificate-authority-data: ${aws_eks_cluster.eks.certificate_authority.0.data}
  name: kubernetes
contexts:
- context:
    cluster: kubernetes
    user: aws
  name: aws
current-context: aws
kind: Config
preferences: {}
users:
- name: aws
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1alpha1
      command: aws-iam-authenticator
      args:
        - "token"
        - "-i"
        - "${var.cluster-name}"
KUBECONFIG
}

output "config-map-aws-auth" {
  value = "${local.config-map-aws-auth}"
}

output "kubeconfig" {
  value = "${local.kubeconfig}"
}

output "repository_url_static_service" {
  value = "${aws_ecr_repository.static_service.repository_url}"
}

output "repository_url_frontend_service" {
  value = "${aws_ecr_repository.frontend_service.repository_url}"
}

output "repository_url_newsfeed_service" {
  value = "${aws_ecr_repository.newsfeed_service.repository_url}"
}

output "repository_url_quotes_service" {
  value = "${aws_ecr_repository.quotes_service.repository_url}"
}

output "codecommit_repository_http_url"{
  value = "${aws_codecommit_repository.repo.clone_url_http}"
}

output "jenkinsPassword"{
  value = "${random_string.password.result}"
}

output "jenkins_IP"{
  value = "${aws_instance.jenkins_master.public_ip}"
}

data "template_file" "jenkinsfile" {
  template = "${file("${path.module}/scripts/Jenkinsfile.tpl")}"
  vars = {
        ECR_REGISTRY  = join("",["http://",split("/",aws_ecr_repository.static_service.repository_url)[0]])
        GIT_REPO        = "${aws_codecommit_repository.repo.clone_url_http}"
        EKS_CLUSTER     = "${var.cluster-name}"
        FRONT_APP_PORT = "8070"
        NEWS_APP_PORT = "8080"
        QUOTES_APP_PORT = "8090"
        STATIC_URL = "http://static-content:8000"
        QUOTE_SERVICE_URL = "http://quotes:8090"
        NEWSFEED_SERVICE_URL = "http://newsfeed:8080"
        REGION = "us-east-1"
  }
}

resource "null_resource" "export_rendered_template" {
  provisioner "local-exec" {
    command = "cat > Jenkinsfile <<EOL\n${data.template_file.jenkinsfile.rendered}\nEOL"
  }
}

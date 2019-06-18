
variable jenkins_instance_type {}

resource "random_string" "password" {
 length = 16
 special = false
}
data "template_file" "userdata" {
  template = "${file("${path.module}/scripts/jenkins-setup.sh.tpl")}"
  vars = {
        username     = "admin"
        plaintext_password = "${random_string.password.result}"
        GIT_REPO     = "${aws_codecommit_repository.repo.clone_url_http}"
  }
}

resource "aws_iam_role" "jenkins_role" {
  name = "${var.cluster-name}-jenkins-master-role"

  assume_role_policy = <<POLICY
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
POLICY
}

resource "aws_iam_policy" "jenkins_eks_policy" {
    name = "jenkins_policy"
    path = "/"
    policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "eks:*"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
              "codecommit:*"
            ],
            "Resource": "*"
        }
    ]
}
POLICY
}

resource "aws_iam_policy_attachment" "jenkins-policy-attach" {
  name       = "jenkins-attachment"
  roles      = ["${aws_iam_role.jenkins_role.name}"]
  policy_arn = "${aws_iam_policy.jenkins_eks_policy.arn}"
}

resource "aws_iam_role_policy_attachment" "jenkins-AWSCodeCommitFullAccess" {
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeCommitFullAccess"
  role       = "${aws_iam_role.jenkins_role.name}"
}

resource "aws_iam_role_policy_attachment" "jenkins-AmazonEC2ContainerRegistryFullAccess" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
  role       = "${aws_iam_role.jenkins_role.name}"
}
resource "aws_iam_instance_profile" "jenkins_profile" {
  name  = "jenkins_node_profile"
  roles = ["${aws_iam_role.jenkins_role.name}"]
}

data "aws_ami" "amazon_linux" {
  most_recent = true

  owners = ["amazon"]

  filter {
    name = "name"

    values = [
      "amzn-ami-hvm-*-x86_64-gp2",
    ]
  }

  filter {
    name = "owner-alias"

    values = [
      "amazon",
    ]
  }
}

resource "aws_security_group" "jenkins_sg" {
  name        = "jenkins-node-sg"
  description = "Security group for Jenkins Server"
  vpc_id      = "${aws_vpc.eks.id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = "${
    map(
     "Name", "${var.cluster-name}-jenkins-sg",
    )
  }"
}

resource "aws_security_group_rule" "jenkins-ingress-ssh" {
  description              = "Allow SSH Access"
  from_port                = 22
  protocol                 = "tcp"
  cidr_blocks              = ["0.0.0.0/0"]
  security_group_id        = "${aws_security_group.jenkins_sg.id}"
  to_port                  = 22
  type                     = "ingress"
}

resource "aws_security_group_rule" "jenkins-ingress-http" {
  description              = "Allow http Access"
  from_port                = 8080
  protocol                 = "tcp"
  cidr_blocks              = ["0.0.0.0/0"]
  security_group_id        = "${aws_security_group.jenkins_sg.id}"
  to_port                  = 8080
  type                     = "ingress"
}
resource "aws_instance" "jenkins_master" {
  ami                         = "${data.aws_ami.amazon_linux.id}"
  instance_type               = "${var.jenkins_instance_type}"
  key_name                    = "${var.node-key}"
  vpc_security_group_ids      = ["${aws_security_group.jenkins_sg.id}"]
  subnet_id                   = "${aws_subnet.eks.*.id[0]}"
  associate_public_ip_address = true
  user_data = "${data.template_file.userdata.rendered}"

  root_block_device {
    volume_type           = "gp2"
    volume_size           = 20
    delete_on_termination = true
  }
  iam_instance_profile   = "${aws_iam_instance_profile.jenkins_profile.name}"

  tags="${
    map(
      "Name", "jenkins_master",
      "Author", "Ricard Underwood",
      "Tool", "Terraform",
    )
  }"
}

/*resource "null_resource" "export_bash_template" {
  provisioner "local-exec" {
    command = "cat > jenkins-setup.sh <<EOL\n${data.template_file.userdata.rendered}\nEOL"
  }
}*/
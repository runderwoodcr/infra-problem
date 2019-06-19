
Deploy a full AWS IaaS using EKS cluster, ECR registry, CodeCommit Repository and Jenkins CICD with Terraform

## What resources are created

1. VPC
2. Internet Gateway (IGW)
3. Public and Private Subnets
4. Security Groups, Route Tables and Route Table Associations
5. IAM roles, instance profiles and policies
6. An EKS Cluster
7. Autoscaling group and Launch Configuration
8. Worker Nodes in a private Subnet
9. ECR repository for each image
10. CodeCommit Repository to upload the code
11. Jenkins Server to perform the Build and Deployment
12. The ConfigMap required to register Nodes with EKS
13. KUBECONFIG file to authenticate kubectl using the heptio authenticator aws binary

## Configuration

You can configure you config with the following input variables:

| Name                    | Description                       | Default         |
|-------------------------|-----------------------------------|-----------------|
| `cluster-name`          | The name of your EKS Cluster      | `my-cluster`    |
| `aws-region`            | The AWS Region to deploy EKS      | `us-east-1`     |
| `k8s-version`           | The desired K8s version to launch | `1.12`          |
| `node-instance-type`    | Worker Node EC2 instance type     | `t3.xlarge`     |
| `desired-capacity`      | Autoscaling Desired node capacity | `2`             |
| `max-size`              | Autoscaling Maximum node capacity | `5`             |
| `min-size`              | Autoscaling Minimum node capacity | `2`             |
| `vpc-subnet-cidr`       | Subnet CIDR                       | `10.0.0.0/16`   |
| `node-key`              | Key Used for EC2 instances        | `infra_key`     |
| `ecr-static`            | Repository for Static Content     | `static_content`|
| `ecr-front-end`         | Repository for Front-End          | `frontend`      |
| `ecr-newsfeed`          | Repository for News Feeds         | `newsfeed`      |
| `ecr-quotes`            | Repository for Quotes             | `quotes`        |
| `jenkins_instance_type` | Jenkins EC2 instance Type         | `t3.large`      |
| `repo_name`             | Code Repository                   | `infra-problem` |
| `repo_default_branch`   | Repository Default Branch         | `master`        |

At minimum you need to modify the value of `node-key` to match an existing key pair in your AWS account.

### AWS Setup and IAM
> Its assumed that you you know how to create IAM users/roles/policies in AWS so this will not be covered here
> Its also assumed that you know how to install/configure awscli which is also required
The AWS credentials must be associated with a user having at least the following AWS managed IAM policies

* IAMFullAccess
* AutoScalingFullAccess
* AmazonEKSClusterPolicy
* AmazonEKSWorkerNodePolicy
* AmazonVPCFullAccess
* AmazonEKSServicePolicy
* AmazonEKS_CNI_Policy
* AmazonEC2FullAccess
* AWSCodeCommitFullAccess
* AmazonEC2ContainerRegistryFullAccess

In addition, you will need to create the following managed policies

*EKS and ECR*

```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "eks:*"
            ],
            "Resource": "*"
        }
    ]
}
```

> Once you have the User you need to dowload the programmatically keys to be used with the awscli(profile)
You need to download kubectl and aws-iam-authenticator from AWS in order to work with eks, change them to be executable and move them to /usr/bin or /usr/local/bin so they are accessible in the path
You can download both from here:

> kubectl

```https://amazon-eks.s3-us-west-2.amazonaws.com/1.12.7/2019-03-27/bin/linux/amd64/kubectl```

> aws-iam-authenticator

```https://amazon-eks.s3-us-west-2.amazonaws.com/1.12.7/2019-03-27/bin/linux/amd64/aws-iam-authenticator```

### Git
Git client must be installed prior working with this solution.
Run this commands to get git to work with CodeCommit

```bash
git config --global credential.helper '!aws codecommit credential-helper $@' command
git config --global credential.UseHttpPath true
```

### Automated Setup
If you don't want to manually run any of the steps, you can just run the script setup:

```bash
chmod +x setup.sh
./setup.sh [-i -c]
i: Installs the infrastructure
c: Remove the Infrastructure
```
> Once the script execution its completed, grab the url to connect to Jenkins, login into it with the credentials displayed, if by any reason you get prompted to install the plugins, just click in the [x] in the top right of the panel,
once in you can click in the infra-job job and then click in build, that should build the applications and generate the images and then they will be deployed to k8s and you will be able to reach it with the LB information that will be provided at the end of the build job 

### Manual Steps

You need to run the following commands to create the resources with Terraform:

```bash
terraform init
terraform plan
terraform apply
```

### Setup kubectl

Setup your `KUBECONFIG`

```bash
terraform output kubeconfig > ~/.kube/eks-cluster
export KUBECONFIG=~/.kube/eks-cluster
```

### Authorize worker nodes

Get the config from terraform output, and save it to a yaml file:

```bash
terraform output config-map > config-map-aws-auth.yaml
```

Apply the config map to EKS:

```bash
kubectl apply -f config-map-aws-auth.yaml
```

You can verify the worker nodes are joining the cluster

```bash
kubectl get nodes --watch
```
### Clone and Push to Repository

> Because we are working with CodeCommit we need to set the helper for git

```bash
git config --global credential.helper '!aws codecommit credential-helper $@'
git config --global credential.UseHttpPath true
```
From the iac directory, run this commands

```bash
export URL=$(terraform output repository_http_url)
export REPO=$(terraform output repository_name)
export JENKINS=$(terraform output jenkins_public_ip)
```
Then change to the root of the solutions directory and run this commands:

```bash
git clone ${URL}
cd ${REPO}
cp -a ../code/* .
git add .
git commit -m "Your commit message here"  
git push origin master
```
Once done you can go to the IP of Jenkins on port 8080 and login with the username admin and the password

```bash
echo "http://${JENKINS}:8080"
echo "Password: ${PASSWORD}"
```

### Cleaning up

You can destroy this cluster entirely by running:

```bash
terraform plan -destroy
terraform destroy  --force
```

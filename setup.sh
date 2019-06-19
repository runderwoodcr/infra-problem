#!/bin/bash

AWS=$(which aws)
AWS_PROFILE=~/.aws/config
GIT=$(which git)
TF=$(which terraform)
TFv=$(terraform -v | awk '{ print $2 }' |cut -d"." -f2)

if [ -z ${AWS} ]; then
    echo "Could not found AWS CLI, AWS CLI must be installed"
    exit 1
fi

if [ -z ${GIT} ]; then
    echo "Could not found Git Client, Git Client must be installed"
    exit 1
fi

if [ -z ${TF} ]; then
    echo "Could not found Terraform, Terraform v12 or newer must be installed"
    exit 1
fi

if [ "${TFv}" -lt "12" ]; then
    echo "Terraform version must equal or greater than v12"
    exit 1
fi

if [ -z ${AWS_PROFILE} ]; then
    echo "Cound not found a valid profile, an aws profile must be created"
    exit 1
fi

while getopts ":ic" option
do
case "${option}"
in
i) 
    echo "Starting Setup..."
    pushd iac
    #Run Terraform init

    terraform init

    #Run Terraform plan

    terraform plan -out aws-infra

    #Run terraform apply
    echo "About to create infrastructure, this may take 15 to 20 minutes"
    terraform apply aws-infra
    cp Jenkinsfile ../code/Jenkinsfile
    terraform output config-map > config-map-aws-auth.yaml
    if [ ! -f ~/.kube ]; then
        mkdir -p ~/.kube
    fi
    if [ -f ~/.kube/eks-cluster ]; then
        rm -f ~/.kube/eks-cluster
    fi

    terraform output kubeconfig > ~/.kube/eks-cluster
    export KUBECONFIG=~/.kube/eks-cluster
    kubectl apply -f config-map-aws-auth.yaml
    echo "waiting for the nodes to come online...."
    sleep 20
    kubectl get nodes
    REPO_URL=$(terraform output repository_http_url)
    REPO_NAME=$(terraform output repository_name)
    JENKINS=$(terraform output jenkins_public_ip)
    PASSWORD=$(terraform output Jenkins_Password)
    popd

    echo "Apply git help for CodeCommit"
    git config --global credential.helper '!aws codecommit credential-helper $@'
    git config --global credential.UseHttpPath true

    echo "Clonig Repo "
    git clone "${REPO_URL}"

    pushd ${REPO_NAME}
    cp -a ../code/* .
    echo "Pushing Code to the Repo"
    git add .
    git commit -m "Adding Code to Repo"  
    git push origin master

    echo "To Build and Deploy go to this URL http://${JENKINS}:8080"
    echo "Username: admin"
    echo "Password: ${PASSWORD}"
    exit 0;;
c) 
    echo "Cleaning Setup..."
    export KUBECONFIG=~/.kube/eks-cluster
    pushd iac
    REPO_NAME=$(terraform output repository_name)
    echo "Removing k8s Services"
    kubectl get svc |awk 'NR > 1 {print $1}'| xargs kubectl delete svc
    echo "Removing Deployments"
    kubectl get deployment |awk 'NR > 1 {print $1}' | xargs kubectl delete deployment
    echo "Destroy infrastructure"
    terraform plan -destroy
    terraform destroy -force
    rm -f Jenkinsfile
    rm -f config-map-aws-auth.yaml
    rm -f terraform.tfstate*
    rm -f aws-infra
    rm -fr .terraform
    popd
    rm -fr ${REPO_NAME}
    pushd code
    rm -f Jenkinsfile
    popd
    exit 0;;
esac
done


exit 0

#!/bin/bash

echo "Install Jenkins stable release"
yum remove -y java
yum install -y java-1.8.0-openjdk
wget -O /etc/yum.repos.d/jenkins.repo http://pkg.jenkins-ci.org/redhat-stable/jenkins.repo
rpm --import https://jenkins-ci.org/redhat/jenkins-ci.org.key
yum install -y jenkins
chkconfig jenkins on


echo "Install git"
yum install -y git

echo "Install docker"
yum install -y docker
usermod -a -G docker ec2-user
usermod -a -G docker jenkins
service docker start

echo "Install Lein"
wget https://raw.githubusercontent.com/technomancy/leiningen/stable/bin/lein
chmod a+x lein 
mv lein /usr/bin
lein

echo "Install kubectl and aws-iam-authenticator"
curl -o /tmp/kubectl https://amazon-eks.s3-us-west-2.amazonaws.com/1.12.7/2019-03-27/bin/linux/amd64/kubectl
chmod +x /tmp/kubectl
mv /tmp/kubectl /usr/bin

curl -o /tmp/aws-iam-authenticator https://amazon-eks.s3-us-west-2.amazonaws.com/1.12.7/2019-03-27/bin/linux/amd64/aws-iam-authenticator
chmod +x /tmp/aws-iam-authenticator
mv /tmp/aws-iam-authenticator /usr/bin


echo "Configure Jenkins"

mkdir -p /var/lib/jenkins/init.groovy.d
/bin/cat <<EOM >>/var/lib/jenkins/init.groovy.d/basic-security.groovy
#!groovy

import jenkins.model.*
import hudson.security.*

def instance = Jenkins.getInstance()

println "--> creating local user '${username}'"

def hudsonRealm = new HudsonPrivateSecurityRealm(false)
hudsonRealm.createAccount("${username}","${plaintext_password}")
instance.setSecurityRealm(hudsonRealm)

def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
instance.setAuthorizationStrategy(strategy)
instance.save()
EOM
/bin/cat <<EOM >>/var/lib/jenkins/jenkins.install.UpgradeWizard.state
2.176
EOM
wget https://gist.githubusercontent.com/runderwoodcr/4f3978350f49ddd1991515cb8c3a99ed/raw/161e8eaf13753ac857d2175a549995fdba216430/git_opts
mv git_opts /var/lib/jenkins/git_opts
chown -R jenkins:jenkins /var/lib/jenkins/
runuser -l --shell=/bin/bash jenkins -c 'bash /var/lib/jenkins/git_opts'

wget https://gist.githubusercontent.com/runderwoodcr/5225efae5a65101fab9383dd08b5d42d/raw/50abeb5c60698b36916b7ce6f67724c4fa4c0b3f/install-plugins.sh
chmod +x install-plugins.sh
mv install-plugins.sh /tmp
/bin/cat <<EOM >>/tmp/plugins.txt
ace-editor
amazon-ecr
ant
antisamy-markup-formatter
apache-httpcomponents-client-4-api
authentication-tokens
aws-credentials
aws-java-sdk
blueocean
blueocean-autofavorite
blueocean-bitbucket-pipeline
blueocean-commons
blueocean-configs
blueocean-config-js
blueocean-dashboard
blueocean-display-url
blueocean-events
blueocean-git-pipeline
blueocean-github-pipeline
blueocean-i18n
blueocean-jira
blueocean-jwt
blueocean-personalization
blueocean-pipeline-api-impl
blueocean-pipeline-editor
blueocean-pipeline-scm-api
blueocean-rest
blueocean-rest-impl
blueocean-web
bouncycastle-api
branch-api
build-pipeline-plugin
cloudbees-bitbucket-branch-source
cloudbees-folder
command-launcher
conditional-buildstep
config-file-provider
credentials
credentials-binding
display-url-api
docker-commons
docker-workflow
durable-task
email-ext
embeddable-build-status
external-monitor-job
favorite
git
git-client
git-server
github
github-api
github-branch-source
github-pullrequest
handlebards
handy-uri-templates-2-api
htmlpublisher
jackson2-api
javadoc
jdk-tool
jenkins-design-language
jira
jquery
jquery-detached
jsch
junit
ldap
mailer
matrix-auth
matrix-project
maven-plugin
mercurial
momentjs
pam-auth
parameterized-trigger
pipeline-build-step
pipeline-graph-analysis
pipeline-input-step
pipeline-milestone-step
pipeline-model-api
pipeline-model-declarative-agent
pipeline-model-definition
pipeline-model-extensions
pipeline-multibranch-defaults
pipeline-rest-api
pipeline-stage-step
pipeline-stage-tags-metadata
pipeline-stage-view
plain-credentials
pubsub-light
run-condition
scm-api
script-security
slack
see-gateway
ssh
ssh-agent
ssh-credentials
ssh-slaves
structs
token-macro
variant
windows-slaves
workflow-aggregator
workflow-api
workflow-basic-steps
workflow-cps
workflow-cps-global-lib
workflow-durable-task-step
workflow-job
workflow-multibranch
workflow-scm-step
workflow-step-api
workflow-support
EOM
bash /tmp/install-plugins.sh
/bin/cat <<EOM >>/tmp/infra-job.xml
<?xml version='1.1' encoding='UTF-8'?>
<flow-definition plugin="workflow-job@2.32">
  <actions>
    <org.jenkinsci.plugins.pipeline.modeldefinition.actions.DeclarativeJobAction plugin="pipeline-model-definition@1.3.9"/>
    <org.jenkinsci.plugins.pipeline.modeldefinition.actions.DeclarativeJobPropertyTrackerAction plugin="pipeline-model-definition@1.3.9">
      <jobProperties/>
      <triggers/>
      <parameters/>
      <options/>
    </org.jenkinsci.plugins.pipeline.modeldefinition.actions.DeclarativeJobPropertyTrackerAction>
  </actions>
  <description></description>
  <keepDependencies>false</keepDependencies>
  <properties>
    <hudson.plugins.jira.JiraProjectProperty plugin="jira@3.0.7"/>
  </properties>
  <definition class="org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition" plugin="workflow-cps@2.70">
    <scm class="hudson.plugins.git.GitSCM" plugin="git@3.10.0">
      <configVersion>2</configVersion>
      <userRemoteConfigs>
        <hudson.plugins.git.UserRemoteConfig>
          <url>${GIT_REPO}</url>
        </hudson.plugins.git.UserRemoteConfig>
      </userRemoteConfigs>
      <branches>
        <hudson.plugins.git.BranchSpec>
          <name>*/master</name>
        </hudson.plugins.git.BranchSpec>
      </branches>
      <doGenerateSubmoduleConfigurations>false</doGenerateSubmoduleConfigurations>
      <submoduleCfg class="list"/>
      <extensions/>
    </scm>
    <scriptPath>Jenkinsfile</scriptPath>
    <lightweight>true</lightweight>
  </definition>
  <triggers/>
  <disabled>false</disabled>
</flow-definition>
EOM
wget https://gist.githubusercontent.com/runderwoodcr/adadc426469c4fc1aab0ddcfc1817fc1/raw/be4e4e8afe5d28166458bd7aa97f284f92a92a04/jenkins
mv jenkins /etc/sysconfig/jenkins
service jenkins start
sleep 60
service jenkins stop
service jenkins start
sleep 60
wget http://localhost:8080/jnlpJars/jenkins-cli.jar
java -jar jenkins-cli.jar -auth ${username}:"${plaintext_password}" -s http://localhost:8080 create-job infra-job < /tmp/infra-job.xml

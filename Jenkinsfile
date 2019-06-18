def static_server 
def frontend 
def newsfeeds 
def quotes 
 
pipeline { 
 
    environment{ 
        VERSION = "0.0.${env.BUILD_NUMBER}" 
        FRONT_APP_PORT = "8070" 
        NEWS_APP_PORT = "8080" 
        QUOTES_APP_PORT = "8090" 
        STATIC_URL = "http://static_content:8000" 
        QUOTE_SERVICE_URL = "http://quotes:8090" 
        NEWSFEED_SERVICE_URL = "http://newsfeed:8080" 
        REGISTRY="<registry>" 
        REPOSITORY="<repository>"
        //REGION="us-east-1" 
    } 
    options { 
        // Build auto timeout 
        timeout(time: 60, unit: 'MINUTES') 
    } 
    agent { 
        node{ 
            label 'master' 
        } 
    } 
    stages {
        stage("Git Clone and Setup"){
            steps{
                git "${env.REPOSITORY}" 
                script{
                  bin = "${JENKINS_HOME}/bin"
                  if (!fileExists(bin)){
                    bin.mkdirs()
                  }
                  sh """
                    cd ${bin}
                    if [ ! -f kubectl ]; then
                      curl -o kubectl https://amazon-eks.s3-us-west-2.amazonaws.com/1.12.7/2019-03-27/bin/linux/amd64/kubectl
                      chmod +x kubectl
                    fi
                    if [ ! -f aws-iam-authenticator ]; then
                      curl -o aws-iam-authenticator https://amazon-eks.s3-us-west-2.amazonaws.com/1.12.7/2019-03-27/bin/linux/amd64/aws-iam-authenticator
                      chmod +x aws-iam-authenticator
                    fi
                    if [ ! -f helm ]; then
                      cd ..
                      if [! -f htlm-tmp]; then
                        mkdir helm-tmp
                      fi
                      cd helm-tmp
                      wget https://storage.googleapis.com/kubernetes-helm/helm-v2.13.1-linux-amd64.tar.gz
                      tar zxf helm-v2.13.1-linux-amd64.tar.gz
                      cd linux-amd64
                      mv helm ../../bin/
                      mv tiller ../../bin/
                      cd ../../bin
                      chmod +x helm
                      chmod +x tiller
                    fi
                  """
                // Validate kubectl
                  List<String> env_vars = [
                    "PATH+K8S=${JENKINS_HOME}/bin",
                    "PATH+AWS=${JENKINS_HOME}/.local/bin"]
                  withEnv(env_vars) {
                      sh """
                      if [ ! -f "${JENKINS_HOME}/.kube/config" ]; then
                        aws eks update-kubeconfig --name $K8S_Cluster
                        kubectl cluster-info
                        helm init
                      fi
                      """
                    
                  }
                }
            }
        } 
        stage('Build') 
        { 
            steps{ 
                sh """ 
                    lein 
                    make libs && make clean all 
                """ 
            } 
        }
        stage('Unit Test'){
            steps{
                sh "echo Unit Tests should go here"
            }
        } 
        stage('Image Build'){ 
            steps{ 
                script{ 
                    static_server = docker.build("static_content:${env.VERSION}","-f docker-files/Dockerfile.static .") 
                    frontend = docker.build("frontend:${env.VERSION}", 
                    "--build-arg PORT=${env.FRONT_APP_PORT} \ 
                    --build-arg URL=${env.STATIC_URL} \ 
                    --build-arg QUOTE_URL=${env.QUOTE_SERVICE_URL} \ 
                    --build-arg NEWSFEED_URL=${env.NEWSFEED_SERVICE_URL} \ 
                    -f docker-files/Dockerfile.front-end .") 
                    newsfeeds = docker.build("newsfeed:${env.VERSION}", 
                    "--build-arg PORT='${env.NEWS_APP_PORT}' \ 
                    -f docker-files/Dockerfile.newsfeed .") 
                    quotes = docker.build("quotes:${env.VERSION}", 
                    "--build-arg PORT=${env.QUOTES_APP_PORT} \ 
                    -f docker-files/Dockerfile.quotes .") 
                    sh 'eval $(aws ecr get-login --no-include-email)' 
                    docker.withRegistry("${env.REGISTRY}") { 
                        static_server.push() 
                        frontend.push() 
                        newsfeeds.push() 
                        quotes.push() 
                    } 
                } 
            } 
        } 
             
        stage('Integreation Test'){
            steps{
                sh "echo Integration Tests should go here"
            }
        } 
        stage('Deploy'){ 
            steps{ 
                sh "echo deploy here...." 
            } 
             
        } 
    } 
 
    post 
    { 
        always 
        { 
            // make sure that the Docker image is removed 
            sh "docker rmi static_content:${env.VERSION} | true" 
            sh "docker rmi frontend:${env.VERSION} | true" 
            sh "docker rmi newsfeed:${env.VERSION} | true" 
            sh "docker rmi quotes:${env.VERSION} | true" 
        } 
    } 
 
} 
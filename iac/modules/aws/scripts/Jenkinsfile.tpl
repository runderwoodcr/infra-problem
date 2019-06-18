def static_server
def frontend
def newsfeeds
def quotes

pipeline {

    environment{
        VERSION = "0.0.\$${env.BUILD_NUMBER}"
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
                
                script{
                // Validate kubectl
                sh """
                if [ ! -f ~/.kube/config ]; then
                mkdir -p ~/.kube
                aws eks update-kubeconfig --name ${EKS_CLUSTER} --region ${REGION}
                kubectl cluster-info
                fi
                """
                    
                  
                }
                git "${GIT_REPO}"
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
        stage('Image Build'){
            steps{
                script{
                    static_server = docker.build("static-content:\$${env.VERSION}","-f docker-files/Dockerfile.static .")
                    frontend = docker.build("frontend:\$${env.VERSION}",
                    "--build-arg PORT=${FRONT_APP_PORT} --build-arg URL=${STATIC_URL} --build-arg QUOTE_URL=${QUOTE_SERVICE_URL} --build-arg NEWSFEED_URL=${NEWSFEED_SERVICE_URL} -f docker-files/Dockerfile.front-end .")
                    newsfeeds = docker.build("newsfeed:\$${env.VERSION}", "--build-arg PORT='${NEWS_APP_PORT}' -f docker-files/Dockerfile.newsfeed .")
                    quotes = docker.build("quotes:\$${env.VERSION}", "--build-arg PORT=${QUOTES_APP_PORT} -f docker-files/Dockerfile.quotes .")
                    sh """
                        chmod +x ecr_auth.sh
                        ./ecr_auth.sh
                    """
                    docker.withRegistry("${ECR_REGISTRY}") {
                        static_server.push()
                        static_server.push("latest")
                        frontend.push()
                        frontend.push("latest")
                        newsfeeds.push()
                        newsfeeds.push("latest")
                        quotes.push()
                        quotes.push("latest")
                    }
                }
            }
        }
            
        
        stage('Deploy'){
            steps{
                sh """
                    kubectl apply -f k8s/static.yml
                    kubectl apply -f k8s/static-service.yml
                    kubectl apply -f k8s/newsfeed.yml
                    kubectl apply -f k8s/newsfeed-service.yml
                    kubectl apply -f k8s/quotes.yml
                    kubectl apply -f k8s/quotes-service.yml
                    kubectl apply -f k8s/frontend.yml
                    kubectl apply -f k8s/lb.yml
                    echo 'Allow a few moments while ELB is created'
                    sleep 30
                    kubectl get svc frontend-lb
                """
            }
            
        }
    }

    post
    {
        always
        {
            // make sure that the Docker image is removed
            sh "docker rmi static-content:\$${env.VERSION} | true"
            sh "docker rmi frontend:\$${env.VERSION} | true"
            sh "docker rmi newsfeed:\$${env.VERSION} | true"
            sh "docker rmi quotes:\$${env.VERSION} | true"
        }
    }

}
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
        REGISTRY=""
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
        stage('Build')
        {
            steps{
                git 'https://github.com/runderwoodcr/infra-problem.git'
                sh """
                    [ ! -f "/usr/local/bin/lein" ] && { wget https://raw.githubusercontent.com/technomancy/leiningen/stable/bin/lein; chmod a+x lein; mv lein "/usr/local/bin"; lein; }
                    make libs && make clean all
                """
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
                    docker.withRegistry("${env.REGISTRY}") {
                        static_server.push()
                        frontend.push()
                        newsfeeds.push()
                        quotes.push()
                    }
                }
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
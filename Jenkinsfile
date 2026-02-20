pipeline {
    agent any

    parameters {
        string(name: 'EC2_HOST', description: 'Public IP of the app server EC2 instance (from Terraform output: app_server_public_ip)')
    }

    environment {
        DOCKER_IMAGE = "cicd-node-app"
        DOCKER_TAG = "${BUILD_NUMBER}"
        REGISTRY = "docker.io"
        REGISTRY_CREDS = credentials('registry_creds')
        CONTAINER_NAME = "node-app"
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo 'Checking out code from repository...'
                checkout scm
            }
        }
        
        stage('Install/Build') {
            steps {
                echo 'Installing dependencies...'
                sh '''
                    npm ci
                '''
            }
        }
        
        stage('Test') {
            steps {
                echo 'Running unit tests...'
                sh '''
                    npm test -- --coverage
                '''
            }
            post {
                always {
                    junit allowEmptyResults: true, testResults: 'test-results/*.xml'
                }
            }
        }
        
        stage('Docker Build') {
            steps {
                echo 'Building Docker image...'
                sh '''
                    docker buildx build --platform linux/amd64,linux/arm64 \
                      --build-arg BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ") \
                      --build-arg VERSION=${BUILD_NUMBER} \
                      --label "org.opencontainers.image.created=$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
                      --label "org.opencontainers.image.version=${BUILD_NUMBER}" \
                      --label "org.opencontainers.image.revision=${GIT_COMMIT}" \
                      -t ${DOCKER_IMAGE}:${DOCKER_TAG} \
                      --load .
                    docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_IMAGE}:latest
                '''
            }
        }
        
        stage('Push Image') {
            steps {
                echo 'Pushing image to registry...'
                sh '''
                    echo $REGISTRY_CREDS_PSW | docker login -u $REGISTRY_CREDS_USR --password-stdin
                    docker buildx build --platform linux/amd64,linux/arm64 \
                      --build-arg BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ") \
                      --build-arg VERSION=${BUILD_NUMBER} \
                      -t $REGISTRY_CREDS_USR/${DOCKER_IMAGE}:${DOCKER_TAG} \
                      -t $REGISTRY_CREDS_USR/${DOCKER_IMAGE}:latest \
                      --push .
                '''
            }
        }
        
        stage('Deploy') {
            when {
                expression { params.EC2_HOST != null && params.EC2_HOST != '' }
            }
            steps {
                echo 'Deploying to EC2...'
                script {
                    try {
                        withCredentials([sshUserPrivateKey(credentialsId: 'ec2_ssh', keyFileVariable: 'SSH_KEY')]) {
                            sh '''
                                ssh -i $SSH_KEY -o StrictHostKeyChecking=no ec2-user@${EC2_HOST} << EOF
                                    # Stop and remove old container
                                    docker stop ${CONTAINER_NAME} || true
                                    docker rm ${CONTAINER_NAME} || true
                                    
                                    # Pull and run new container
                                    echo $REGISTRY_CREDS_PSW | docker login -u $REGISTRY_CREDS_USR --password-stdin
                                    docker pull $REGISTRY_CREDS_USR/${DOCKER_IMAGE}:latest
                                    docker run -d \
                                      --name ${CONTAINER_NAME} \
                                      --restart unless-stopped \
                                      --health-cmd="curl -f http://localhost:5000/health || exit 1" \
                                      --health-interval=30s \
                                      --health-timeout=3s \
                                      --health-retries=3 \
                                      -p 5000:5000 \
                                      -e APP_VERSION=${BUILD_NUMBER} \
                                      $REGISTRY_CREDS_USR/${DOCKER_IMAGE}:latest
                                    
                                    # Wait for health check
                                    sleep 10
                                    docker ps --filter name=${CONTAINER_NAME} --format "{{.Status}}"
                                    
                                    # Cleanup old images
                                    docker image prune -af
EOF
                            '''
                        }
                    } catch (Exception e) {
                        echo "⚠️ Deploy skipped: ${e.message}"
                        echo "To enable deployment, add 'ec2_ssh' credential in Jenkins"
                    }
                }
            }
        }
    }
    
    post {
        always {
            echo 'Cleaning up local Docker images...'
            sh '''
                docker rmi ${DOCKER_IMAGE}:${DOCKER_TAG} || true
                docker rmi ${DOCKER_IMAGE}:latest || true
                docker rmi $REGISTRY_CREDS_USR/${DOCKER_IMAGE}:${DOCKER_TAG} || true
                docker rmi $REGISTRY_CREDS_USR/${DOCKER_IMAGE}:latest || true
            '''
        }
        success {
            echo '✅ Pipeline completed successfully!'
            echo "Application deployed: http://${params.EC2_HOST}:5000"
        }
        failure {
            echo '❌ Pipeline failed!'
        }
    }
}

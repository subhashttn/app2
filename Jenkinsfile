pipeline {
    agent any

    environment {
        AWS_REGION = 'us-west-2'
        ECR_REPO = '148761684097.dkr.ecr.us-west-2.amazonaws.com/app2'
        IMAGE_TAG = "hotfix-${BUILD_NUMBER}-${BUILD_DATE}"
        DOCKER_IMAGE = "${ECR_REPO}:${IMAGE_TAG}"
        EKS_CLUSTER_NAME = 'bootcamp'
        NAMESPACE = 'app2'
        AWS_CREDENTIALS_ID = 'aws-cred'
    }

    stages {
        stage('check if Merge'){
            steps{
                script {
                    def isMergeCommit = sh(script: "git log -1 --pretty=%P | wc -w", returnStdout: true).trim()
                    if (isMergeCommit.toInteger() <2) {
                    echo "Not a merge commit. Skipping pipeline."
                    currentBuild.result = 'ABORTED'
                    error("Abort: Not a merge into hotfix branch.")
                    }
                }
            }
        }
        stage('Clone Repository') {
            steps {
                git credentialsId: 'git-ssh-key', url: 'git@github.com:subhashttn/app2.git', branch: 'hotflix'
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    sh "docker build -t ${DOCKER_IMAGE} ."
                }
            }
        }

        stage('Push Image to ECR') {
            steps {
                script {
                    withCredentials([aws(credentialsId: AWS_CREDENTIALS_ID)]) {
                        sh """
                        aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REPO}
                        docker push ${DOCKER_IMAGE}
                        """
                    }
                }
            }
        }

        stage('Cleanup Docker Images') {
            steps {
                script {
                    sh "docker rmi -f ${DOCKER_IMAGE} || true"
                    sh "docker system prune -a -f || true"
                }
            }
        }

        stage('Deploy to EKS') {
            steps {
                script {
                    withCredentials([aws(credentialsId: AWS_CREDENTIALS_ID)]) {
                        sh """
                        aws eks update-kubeconfig --name ${EKS_CLUSTER_NAME} --region ${AWS_REGION}

                        # Create namespace if not exists
                        kubectl get ns ${NAMESPACE} || kubectl create ns ${NAMESPACE}

                        export IMAGE_TAG=${IMAGE_TAG}
                        envsubst < k8s/deployment.yaml > k8s/deployment-updated.yaml

                        kubectl apply -f k8s/deployment-updated.yaml -n ${NAMESPACE}
                        kubectl apply -f k8s/service.yaml -n ${NAMESPACE}
                        """
                    }
                }
            }
        }
    } 

    post {
        success {
            script {
                echo "Deployment successful!"
                mail to: 'abashkumarshah@gmail.com', subject: 'App2 Deployment Success', body: 'App2 deployed successfully to EKS.'
            }
        }
        failure {
            script {
                echo "Deployment failed!"
                mail to: 'abashkumarshah@gmail.com', subject: 'App2 Deployment Failed', body: 'App2 deployment failed. Please check Jenkins logs.'
            }
        }
    }
} 

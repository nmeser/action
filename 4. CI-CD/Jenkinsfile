// pipeline için env. variables tanımlanır.
pipeline {
    agent any
    environment {
        PATH=sh(script:"echo $PATH:/usr/local/bin", returnStdout:true).trim()
        AWS_REGION = "eu-central-1"
        AWS_ACCOUNT_ID=sh(script:'export PATH="$PATH:/usr/local/bin" && aws sts get-caller-identity --query Account --output text', returnStdout:true).trim()
        ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
        // ECR_REGISTRY = "0xxxxxxxxxxxx.dkr.ecr.us-east-1.amazonaws.com"
        APP_REPO_NAME = "myflaskapp/ci_cd"
        APP_NAME = "FlaskApp"
        HOME_FOLDER = "/home/ec2-user"
        GIT_FOLDER = sh(script:'echo ${GIT_URL} | sed "s/.*\\///;s/.git$//"', returnStdout:true).trim()
    }
  
    stages {
         // 1. adımda öncelikle imageların depolanacağı AWS-ECR repo açılır. 
        stage('Create ECR Repo') {
            steps {

                echo 'Creating ECR Repo for App'

                sh """
                   aws ecr create-repository \
                    --repository-name ${APP_REPO_NAME} || true \
                    --image-scanning-configuration scanOnPush=false \
                    --image-tag-mutability MUTABLE \
                    --region ${AWS_REGION}
                """
            }
        }
        // image build edilir.
        stage('Build App Docker Image') {
            steps {
                echo 'Building App Image'
                sh 'docker build --force-rm -t "$ECR_REGISTRY/$APP_REPO_NAME:latest" .'
                sh 'docker image ls'
            }
        }
        // Oluşturulan image repoya push edilir.
        stage('Push Image to ECR Repo') {
            steps {
                echo 'Pushing App Image to ECR Repo'
                sh 'aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin "$ECR_REGISTRY"'
                sh 'docker push "$ECR_REGISTRY/$APP_REPO_NAME:latest"'
            }
        }
        // image ECR dan pull edilir ve container oluşturularak koşturulur.
        stage('Deploy') {
            steps {
                sh 'docker container ls -a'                
                sh 'aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin "$ECR_REGISTRY"'
                sh 'docker pull "$ECR_REGISTRY/$APP_REPO_NAME:latest"'
                sh 'docker container run --name myflaskapp -p 5000:5000 "$ECR_REGISTRY/$APP_REPO_NAME:latest"'
                
            }
        }        
        
    }
    
    post {
        // Oluşturulan imagelar ve containerlar silinir
        always {
            echo 'Deleting all local images'
            sh 'docker image prune -af'
            sh 'docker container rm -f myflaskapp'
        }
        // pipeline hata ile karşılaşması durumunda ECR repo silinir.
        failure {

            echo 'Delete the Image Repository on ECR due to the Failure'
            sh """
                aws ecr delete-repository \
                  --repository-name ${APP_REPO_NAME} \
                  --region ${AWS_REGION}\
                  --force
                """          
        }
    }
}

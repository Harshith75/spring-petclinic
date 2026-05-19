pipeline {
    agent {
        kubernetes {
yaml '''
apiVersion: v1
kind: Pod
metadata:
  labels:
    app: test
spec:
  containers:
  - name: kubectl-cli
    image: bitnami/kubectl:latest
    command:
    - cat
    tty: true

  - name: docker
    image: docker:latest
    command:
    - cat
    tty: true
    volumeMounts:
    - mountPath: /var/run/docker.sock
      name: docker-sock

  - name: sonarcli
    image: sonarsource/sonar-scanner-cli:latest
    command:
    - cat
    tty: true

  - name: maven
    image: maven:3.8.6-eclipse-temurin-17
    volumeMounts:
    - mountPath: "/root/.m2/repository"
      name: cache
    command:
    - cat
    tty: true

  - name: git
    image: bitnami/git:latest
    command:
    - cat
    tty: true

  volumes:
  - name: cache
    persistentVolumeClaim:
      claimName: maven-cache
  - name: docker-sock
    hostPath:
      path: /var/run/docker.sock
'''


        }
    }
    environment {
        DOCKERHUB_USERNAME = "harshithdockerhub"
        APP_NAME = "spring-petclinic"
        IMAGE_NAME = "${DOCKERHUB_USERNAME}" + "/" + "${APP_NAME}"
        IMAGE_TAG = "${BUILD_NUMBER}"
    }


    stages {
        stage('Git Checkout') {
            steps {
                container('git') {
                    git branch: 'main', url: 'https://github.com/Harshith75/spring-petclinic.git'
                }
            }
        }
        stage('Build') {
            steps {
                container('maven') {
                    sh 'mvn -Dmaven.test.failure.ignore=true clean package'
                }
            }
            post {
                success {
                    junit '**/target/surefire-reports/*.xml'
                }
            }
        }
       stage('Sonar Scan') {
    steps {
        container('sonarcli') {
            withSonarQubeEnv(credentialsId: 'sonarqubetoken', installationName: 'sonarqubescanner') {
                sh '''
                  /opt/sonar-scanner/bin/sonar-scanner \
                    -Dsonar.projectKey=petclinicsonar \
                    -Dsonar.projectName=petclinicsonar \
                    -Dsonar.projectVersion=1.0 \
                    -Dsonar.sources=src/main \
                    -Dsonar.tests=src/test \
                    -Dsonar.java.binaries=target/classes \
                    -Dsonar.sourceEncoding=UTF-8
                '''
            }
        }
    }
}

        stage('Wait for Quality Gate'){
      
        steps{
          container('sonarcli'){
          timeout(time: 1, unit: 'HOURS') {
            waitForQualityGate abortPipeline: true
          }
        }
      }
      post {
        success {
            container('docker'){
                sh 'docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .'
                sh "docker tag $IMAGE_NAME:$IMAGE_TAG $IMAGE_NAME:latest"
                withCredentials([usernamePassword(credentialsId: 'dockercredentials', passwordVariable: 'P', usernameVariable: 'U')]) {
                sh "docker login -u $U -p $P"
                sh "docker push $IMAGE_NAME:$IMAGE_TAG"
                sh "docker push $IMAGE_NAME:latest"
          }
          sh "docker rmi $IMAGE_NAME:$IMAGE_TAG"
          sh "docker rmi $IMAGE_NAME:latest"
        }
      }
            }
        }
        stage ('deploy to kubernetes') {
            steps {
                container ('kubectl-cli') {
                    sh 'kubectl apply -f deployment.yaml'
                }            
                }

        }
      }
    }



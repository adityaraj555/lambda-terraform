def accountmap = [
  'platform-dev':'356071200662',
  'platform-test':'952028532360',
]
pipeline {
  agent {
    kubernetes {
      yamlFile 'build/jenkins/pod.yaml'
    }
  }
  options {
      buildDiscarder(logRotator(numToKeepStr: '30', artifactNumToKeepStr: '30'))
  }
  parameters {
    string(name: "DOMAIN",             defaultValue: "evml",      description: "Platform Domain Name")
    choice(name: "LAMBDA",             choices: ["evml-start-sfn", "evml-simple-lambda", "evml-simple-notify-result"],    description: "Select the lambda for deploy")
    choice(name: "ECR_ACCOUNT_ID",     choices: "176992832580",                      description: "ECR account ID (default: platform-ci)")
    choice(name: "ECR_REGION",         choices: "us-east-2",                         description: "ECR region")
    string(name: "TAG_NAME",           defaultValue: '',                             description: "ECR Image TagName default: \${REVISION}.\${BUILD_NUMBER}")
    string(name: "GITHUB_CREDENTIALS", defaultValue: "platform-github-token",        description: "Platform GitHub credentials")
    string(name: "SLACK_CREDENTIALS",  defaultValue: "slackintegration",             description: "Slack credentials for Graph Warehouse notifications")
  }

  environment {
    AWS_CREDENTIALS       = credentials("JenkinsDeploymentUser")
    AWS_ACCESS_KEY_ID     = "${env.AWS_CREDENTIALS_USR}"
    AWS_SECRET_ACCESS_KEY = "${env.AWS_CREDENTIALS_PSW}"
    DEPLOYMENT_ROLE       = "JenkinsDeploymentRole"
  }

  stages {
    stage('env') {
      steps {
        script {
          env.REVISION   = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
          env.ECR_IMAGE  = "${ECR_ACCOUNT_ID}.dkr.ecr.${ECR_REGION}.amazonaws.com/${DOMAIN}/${LAMBDA}:${TAG_NAME}"
          if (params.TAG_NAME.isEmpty()) {
              env.ECR_IMAGE  = "${ECR_ACCOUNT_ID}.dkr.ecr.${ECR_REGION}.amazonaws.com/${DOMAIN}/${LAMBDA}:${REVISION}.${BUILD_NUMBER}"
          }
          env.RUN_IMAGE_STAGE  = 'true'
        }
      }
    }

    // stage('analysis') {
    //    when {
    //      expression { env.RUN_IMAGE_STAGE=='true' }
    //    }
    //    steps {
    //      container('sonarqube') {
    //        withCredentials([string(credentialsId: 'platform-sonarqube-token', variable: 'sonarLogin')]) {
    //          sh "/usr/bin/python3 -m pip install --upgrade pip"
    //          sh  "pip3 install -r ${env.WORKSPACE}/lambda/${params.LAMBDA}/requirements.txt"
    //          sh "coverage run --source=. -m pytest && coverage report && coverage xml"
    //          sh "/opt/sonar-scanner/bin/sonar-scanner -e -Dproject.settings=${env.WORKSPACE}/build/sonarqube/sonar-project.properties -Dsonar.login=${sonarLogin} -Dsonar.branch.name=${env.GIT_BRANCH}"
    //        }
    //      }
    //   }
    // }

    stage('Image Build') {
      when {
        expression { env.RUN_IMAGE_STAGE=='true' }
      }
      steps {
        container('kaniko') {
          withAWS(role: "${DEPLOYMENT_ROLE}", roleAccount: "${ECR_ACCOUNT_ID}", region: "${ECR_REGION}"){
            withCredentials([usernamePassword(credentialsId: ' jfrog-svc-ac-password', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
              script{
                sh "/kaniko/executor -f ./build/docker/Dockerfile --build-arg FUNCTION_NAME=$LAMBDA --build-arg ARTIFACTORY_USERNAME=$USERNAME --build-arg ARTIFACTORY_PASSWORD=$PASSWORD -c `pwd` --skip-tls-verify --cache=true --destination=${env.ECR_IMAGE}"
              }
            }
          }
        }
      }
    }
  }

  post {
    success {
      withCredentials([string(credentialsId: "${env.SLACK_CREDENTIALS}", variable: "SLACK_TOKEN")]) {
      slackSend(
        teamDomain: "eagleview",
          channel: "#evml-cicd",
          token: "$SLACK_TOKEN",
        color: "good",
        message: """
BUILT LAMBDA *${env.LAMBDA}* <${BUILD_URL}|${BUILD_DISPLAY_NAME}>
```
  LAMBDA:       ${env.LAMBDA}
  DOMAIN:        ${env.DOMAIN}
  BRANCH:        ${env.GIT_BRANCH}
  REVISION:      ${env.REVISION}
  BUILD_NUMBER:  ${env.BUILD_NUMBER}
  ECR_IMAGE:     ${env.ECR_IMAGE}
```
"""
      )
    }
    }
    failure {
      withCredentials([string(credentialsId: "${env.SLACK_CREDENTIALS}", variable: "SLACK_TOKEN")]) {
      slackSend(
        teamDomain: "eagleview",
          channel: "#evml-cicd",
          token: "$SLACK_TOKEN",
        color: "danger",
        message: """
FAILED TO BUILD LAMBDA *${env.LAMBDA}* <${BUILD_URL}|${BUILD_DISPLAY_NAME}>
```
  LAMBDA:       ${env.LAMBDA}
  DOMAIN:        ${env.DOMAIN}
  BRANCH:        ${env.GIT_BRANCH}
  REVISION:      ${env.REVISION}
  BUILD_NUMBER:  ${env.BUILD_NUMBER}
  ECR_IMAGE:     ${env.ECR_IMAGE}
```
"""
      )
    }
  }
  }

}
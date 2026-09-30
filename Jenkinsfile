pipeline {
    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timeout(time: 30, unit: 'MINUTES')
    }

    parameters {
        booleanParam(name: 'PROVISION_INFRA', defaultValue: false,
                     description: 'Run terraform apply to create/update the AWS EC2 infrastructure')
        booleanParam(name: 'DESTROY_INFRA', defaultValue: false,
                     description: 'Run terraform destroy and skip build/deploy stages')
    }

    environment {
        IMAGE_REPO   = 'your-dockerhub-username/cicd-python-app'
        IMAGE_TAG    = "${env.BUILD_NUMBER}"
        AWS_REGION   = 'ap-south-1'
        TF_IN_AUTOMATION = 'true'
        ANSIBLE_HOST_KEY_CHECKING = 'False'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Install & Lint') {
            when { expression { !params.DESTROY_INFRA } }
            steps {
                sh '''
                    python3 -m venv venv
                    . venv/bin/activate
                    pip install --upgrade pip
                    pip install -r requirements-dev.txt
                    flake8 app tests
                '''
            }
        }

        stage('Unit Tests') {
            when { expression { !params.DESTROY_INFRA } }
            steps {
                sh '''
                    . venv/bin/activate
                    pytest --junitxml=test-results.xml
                '''
            }
            post {
                always {
                    junit allowEmptyResults: true, testResults: 'test-results.xml'
                }
            }
        }

        stage('Build Docker Image') {
            when { expression { !params.DESTROY_INFRA } }
            steps {
                sh '''
                    docker build \
                        --build-arg APP_VERSION=${IMAGE_TAG} \
                        -t ${IMAGE_REPO}:${IMAGE_TAG} \
                        -t ${IMAGE_REPO}:latest .
                '''
            }
        }

        stage('Push to Docker Hub') {
            when { expression { !params.DESTROY_INFRA } }
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub-creds',
                                                  usernameVariable: 'DH_USER',
                                                  passwordVariable: 'DH_PASS')]) {
                    sh '''
                        echo "${DH_PASS}" | docker login -u "${DH_USER}" --password-stdin
                        docker push ${IMAGE_REPO}:${IMAGE_TAG}
                        docker push ${IMAGE_REPO}:latest
                    '''
                }
            }
        }

        stage('Terraform Provision') {
            when { expression { params.PROVISION_INFRA && !params.DESTROY_INFRA } }
            steps {
                withCredentials([
                    usernamePassword(credentialsId: 'aws-creds',
                                     usernameVariable: 'AWS_ACCESS_KEY_ID',
                                     passwordVariable: 'AWS_SECRET_ACCESS_KEY'),
                    sshUserPrivateKey(credentialsId: 'ec2-ssh-key', keyFileVariable: 'SSH_KEY')
                ]) {
                    dir('terraform') {
                        sh '''
                            export TF_VAR_public_key="$(ssh-keygen -y -f ${SSH_KEY})"
                            export TF_VAR_aws_region=${AWS_REGION}
                            terraform init -input=false
                            terraform validate
                            terraform plan -input=false -out=tfplan
                            terraform apply -input=false -auto-approve tfplan
                        '''
                    }
                }
            }
        }

        stage('Deploy with Ansible') {
            when { expression { !params.DESTROY_INFRA } }
            steps {
                withCredentials([sshUserPrivateKey(credentialsId: 'ec2-ssh-key', keyFileVariable: 'SSH_KEY')]) {
                    script {
                        env.EC2_IP = sh(script: 'cd terraform && terraform output -raw public_ip',
                                        returnStdout: true).trim()
                    }
                    sh '''
                        ansible-galaxy collection install -r ansible/requirements.yml
                        ansible-playbook ansible/playbook.yml \
                            -i "${EC2_IP}," \
                            -u ubuntu \
                            --private-key "${SSH_KEY}" \
                            --extra-vars "docker_image=${IMAGE_REPO} docker_tag=${IMAGE_TAG}"
                    '''
                }
            }
        }

        stage('Smoke Test') {
            when { expression { !params.DESTROY_INFRA } }
            steps {
                sh 'curl --fail --retry 10 --retry-delay 5 --retry-connrefused http://${EC2_IP}/health'
            }
        }

        stage('Terraform Destroy') {
            when { expression { params.DESTROY_INFRA } }
            steps {
                withCredentials([
                    usernamePassword(credentialsId: 'aws-creds',
                                     usernameVariable: 'AWS_ACCESS_KEY_ID',
                                     passwordVariable: 'AWS_SECRET_ACCESS_KEY'),
                    sshUserPrivateKey(credentialsId: 'ec2-ssh-key', keyFileVariable: 'SSH_KEY')
                ]) {
                    dir('terraform') {
                        sh '''
                            export TF_VAR_public_key="$(ssh-keygen -y -f ${SSH_KEY})"
                            export TF_VAR_aws_region=${AWS_REGION}
                            terraform init -input=false
                            terraform destroy -input=false -auto-approve
                        '''
                    }
                }
            }
        }
    }

    post {
        always {
            sh 'docker logout || true'
        }
        success {
            echo "Pipeline completed successfully."
        }
        failure {
            echo "Pipeline failed. Check the stage logs above."
        }
    }
}

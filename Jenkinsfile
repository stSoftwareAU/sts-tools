
pipeline {
    agent {
        label 'ec2-large'
    }

    triggers {
        pollSCM( '* 0-8 * * 1-5')
        cron( 'H 3 * * 3') // UTC About Midday Sydney time
    }

    environment {
        GIT_CREDENTIALS = 'e0c8abc2-7a04-4a41-96b1-1d56c0cf1874'
        REPOS_DIR = '.repos/'
    }

    options {
        timeout(time: 1, unit: 'HOURS')
    }

    stages {

        stage('checkout') {
            
            steps {

                dir("${REPOS_DIR}/dga-ckan_web_container") {
                    git branch: "${GIT_BRANCH}",
                        credentialsId: "${GIT_CREDENTIALS}",
                        url: 'https://github.com/AusDTO/dga-ckan_web_container.git'
                }
        
                dir("${REPOS_DIR}/dga-ckan_web_infrastructure") {
                    git branch: "${GIT_BRANCH}",
                        credentialsId: "${GIT_CREDENTIALS}",
                        url: 'https://github.com/AusDTO/dga-ckan_web_infrastructure.git'
                }
        
                dir("${REPOS_DIR}/dga-configure") {
                    git branch: "${GIT_BRANCH}",
                        credentialsId: "${GIT_CREDENTIALS}",
                        url: 'https://github.com/AusDTO/dga-configure.git'
                }
        
                dir("${REPOS_DIR}/dga-golden-image") {
                    git branch: "${GIT_BRANCH}",
                        credentialsId: "${GIT_CREDENTIALS}",
                        url: 'https://github.com/AusDTO/dga-golden-image.git'
                }
        
                dir("${REPOS_DIR}/dga-jenkins-pipeline") {
                    git branch: "${GIT_BRANCH}",
                        credentialsId: "${GIT_CREDENTIALS}",
                        url: 'https://github.com/AusDTO/dga-jenkins-pipeline.git'
                }
    
                dir("${REPOS_DIR}/dga-network-pipeline") {
                    git branch: "${GIT_BRANCH}",
                        credentialsId: "${GIT_CREDENTIALS}",
                        url: 'https://github.com/AusDTO/dga-network-pipeline.git'
                }

                dir("${REPOS_DIR}/dga-push_pull-deploy") {
                    git branch: "${GIT_BRANCH}",
                        credentialsId: "${GIT_CREDENTIALS}",
                        url: 'https://github.com/AusDTO/dga-push_pull-deploy.git'
                }
                
                dir("${REPOS_DIR}/dga-scratch_shutdown") {
                    git branch: "${GIT_BRANCH}",
                        credentialsId: "${GIT_CREDENTIALS}",
                        url: 'https://github.com/AusDTO/dga-scratch_shutdown.git'
                }
                

                dir("${REPOS_DIR}/dga-selenium-tests") {
                    git branch: "${GIT_BRANCH}",
                        credentialsId: "${GIT_CREDENTIALS}",
                        url: 'https://github.com/AusDTO/dga-selenium-tests.git'
                }
            }
        }

        stage('QA') {
            when {
                not {
                    branch 'Develop'
                }
            }
            steps {
                sh """\
                #!/bin/bash
                set -e

                ./build.sh
                """.stripIndent()
            }
                
        }
        stage('Fix') {
            when { branch 'Develop' }
            
            steps {

                sh """\
                    #!/bin/bash
                    set -ex

                    ls -l
                    ls -l ${REPOS_DIR}
                    pwd 

                    ./build.sh --fix --no-push
                    """.stripIndent()

                    // sh """\
                    //     #!/bin/bash
                    //     set -ex
                    //     env
                    //     for d in .repos/*; do
                    //         cd $d
                    //         # git push --set-upstream origin Develop
                    //         git push 
                    //         cd ..
                    //     done
                    // """.stripIndent()
                
            }
        }
    }
}

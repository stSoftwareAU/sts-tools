pipeline {
    agent {
        label 'ec2-large'
    }

    triggers {
        pollSCM( '* 0-8 * * 1-5')
        cron( 'H 3 * * 3') // UTC About Midday Sydney time
    }

    // environment {
    //     GIT_CREDENTIALS = 'e0c8abc2-7a04-4a41-96b1-1d56c0cf1874'
    //     REPOS_DIR = '.repos/'
    // }

    options {
        timeout(time: 1, unit: 'HOURS')
    }

    stages {

        stage('Build') {

            steps {
                sh """\
                #!/bin/bash
                set -e

                ./build.sh
                ./push.sh
                """.stripIndent()
            }
                
        }
        stage('Release') {
            // when { branch 'Develop' }
            
            steps {

                sh """\
                    #!/bin/bash
                    set -ex
                    ./release.sh
                    """.stripIndent()
            }
        }
    }
}

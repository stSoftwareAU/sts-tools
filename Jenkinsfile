pipeline {
    agent {
        label 'ec2-large'
    }

    triggers {
        pollSCM( '* 22,23,0-8 * * 0-5')
        cron( 'H H(2-3) * * H(2-4)') // UTC About Midday Sydney time on a workday.
    }

    options {
      timeout(time: 1, unit: 'HOURS')
      disableConcurrentBuilds()
      parallelsAlwaysFailFast()
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

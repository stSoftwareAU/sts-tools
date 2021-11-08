pipeline {
  agent {
    label 'ec2-large'
  }

  triggers {
    pollSCM( '* * * * *')
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

        sh '''\
            #!/bin/bash
            set -ex

            ./build.sh
            ./push.sh
        '''.stripIndent()
      }
    }
    

    stage( 'Secrets scan'){
      steps{
        sh './secrets_scan.sh'
        sh './test/check.sh'
      }
    }

    stage('CVE scan') {

      steps {
        script {
            sh '''\
            #!/bin/bash
            set -ex

            cp common/IaC/cve-scan.sh ./
            ./cve-scan.sh --allow common/IaC/cve-allow.json
          '''.stripIndent()
        }
      }
      post {
        always {
          archiveArtifacts artifacts: 'cve-scan.json', fingerprint: true
        }
      }
    }

    stage('Release') {
      steps {
        sh '''\
          #!/bin/bash
          set -ex
          ./release.sh
        '''.stripIndent()
      }
    }
  }
}

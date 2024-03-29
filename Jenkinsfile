pipeline {
  agent {
    label 'large'
  }

  triggers {
    pollSCM( '* * * * *')
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
      when {
        environment name: 'BRANCH_NAME', value: 'Develop'
      }
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

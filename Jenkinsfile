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

  parameters {
    booleanParam(name: 'CVE_SCAN_FAILED', defaultValue: false)
  }

  stages {

      stage('Build') {

        steps {
          script{
            /**
            * Keep the COMMIT at the start of the build process so that it doesn't change during the build.
            */
            env.COMMIT_ID=env.GIT_COMMIT
          }
          sh """\
              #!/bin/bash
              set -ex

              ./build.sh
              ./push.sh
          """.stripIndent()
        }                
      }

      stage('CVE scan') {
        when { anyOf{ branch 'Develop'; changeRequest target: 'Develop'} }
        
        steps {
          try{
            sh '''\
              #!/bin/bash
              set -ex
              
              cp common/IaC/cve-scan.sh ./
              ./cve-scan.sh
            '''.stripIndent()
          } catch(err) {
            echo "Caught: ${err}"
            env.CVE_SCAN_FAILED=true
          }
        } 
        post {
          always {
            archiveArtifacts artifacts: 'cve-scan.json', fingerprint: true
          }    
        }
      }

      stage('Prompt'){
        when{ expression { env.CVE_SCAN_FAILED == true}}
        steps{
          script {
            try {
              timeout(time: 15, unit: 'MINUTES') { 
                input( message: 'CVE scan detected issues', ok: "Continue?")
              }
            } catch(err) { // timeout reached or input false
              echo "Caught: ${err}"
              // def user = err.getCauses()[0].getUser()
              // if('SYSTEM' == user.toString()) { // SYSTEM means timeout.
              //   echo "Timeout"
              // } else { 
              //   echo "Aborted by: [${user}]"
              // }
              currentBuild.result = 'FAILURE'
            }
          }
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

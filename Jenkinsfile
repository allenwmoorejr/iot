pipeline {
  agent any

  options {
    ansiColor('xterm')
    timestamps()
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Validate Kubernetes manifests') {
      agent {
        docker {
          image 'bitnami/kubectl:1.27.4'
          args '-u root:root'
        }
      }
      steps {
        sh 'bash scripts/ci/validate-kubernetes-manifests.sh'
      }
    }

    stage('Terraform formatting check') {
      agent {
        docker {
          image 'hashicorp/terraform:1.5.7'
          args '-u root:root'
        }
      }
      steps {
        sh 'bash scripts/ci/check-terraform-format.sh'
      }
    }
  }

  post {
    success {
      echo 'All workflow checks passed successfully.'
    }
    failure {
      echo 'Workflow checks failed. Review the stage logs for details.'
    }
  }
}

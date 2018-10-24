pipeline {
  agent any
  stages {
    stage('Download code') {
      steps {
        readTrusted 'index.rst'
      }
    }
  }
}
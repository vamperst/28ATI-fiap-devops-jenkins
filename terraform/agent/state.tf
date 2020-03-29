terraform {
  backend "s3" {
    bucket = "lab-fiap-SUA TURMA-SEU RM"
    key    = "test-jenkins-agent"
    region = "us-east-1"
  }
}

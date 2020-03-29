output "address_master" {
    value = {
    for instance in aws_instance.jenkins_master:
     instance.id => "http://${instance.public_dns}:8080"
  }
}
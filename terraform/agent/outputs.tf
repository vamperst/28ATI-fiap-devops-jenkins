output "address_agent" {
  value = {
    for instance in aws_instance.jenkins_agent:
     instance.id => instance.public_dns
  }
}
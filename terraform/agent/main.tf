# Specify the provider and access details
provider "aws" {
  region = "${var.aws_region}"
}

variable "project" {
  default = "fiap-lab"
}

data "aws_vpc" "vpc" {
  tags = {
    Name = "${var.project}"
  }
}

data "aws_subnet_ids" "all" {
  vpc_id = "${data.aws_vpc.vpc.id}"

  tags = {
    Tier = "Public"
  }
}

data "aws_subnet" "public" {
  for_each = data.aws_subnet_ids.all.ids
  id = "${each.value}"
}

resource "random_shuffle" "random_subnet" {
  input        = [for s in data.aws_subnet.public : s.id]
  result_count = 1
}

data "aws_instance" "jenkins_master" {
  instance_tags = {
    Stage = "${var.stage}"
    Version = "${var.version_jenkins}"
    Jenkins = "master"
  }
}

data "template_file" "jenkis-agent" {
  template = "${file("${path.module}/script-jenkins-agent.sh")}"
  vars = {
    ip_master = "${data.aws_instance.jenkins_master.private_ip}",
    USERNAME = "admin",
    PASSWORD = "12345678"
  }
}


resource "aws_instance" "jenkins_agent" {
  instance_type = "t2.medium"
  ami           = "${lookup(var.aws_amis, var.aws_region)}"

  count = 1
  root_block_device {
    volume_size = 40
    delete_on_termination = true
  }
  
  subnet_id              = "${random_shuffle.random_subnet.result[0]}"
  vpc_security_group_ids = ["${aws_security_group.jenkins-agent.id}"]
  key_name               = "${var.KEY_NAME}"
  iam_instance_profile = "${aws_iam_instance_profile.jenkins-agent.id}"

  provisioner "file" {
    content      = "${data.template_file.jenkis-agent.rendered}"
    destination = "/tmp/script-jenkins-agent.sh"
}

  provisioner "file" {
    source      = "/home/ubuntu/.aws/config"
    destination = "/tmp/config"
  }

  provisioner "file" {
    source      = "jenkins.service"
    destination = "/tmp/jenkins.service"
  }

provisioner "remote-exec" {
    inline = [
      "sudo cp /tmp/jenkins.service /etc/systemd/system/jenkins.service"
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/script-jenkins-agent.sh",
      "sudo /tmp/script-jenkins-agent.sh",
    ]
  }

  

  connection {
    user        = "${var.INSTANCE_USERNAME}"
    private_key = "${file("${var.PATH_TO_KEY}")}"
    host = "${self.public_dns}"
  }

  tags = {
    Name = "${format("jenkins-agent-%03d", count.index + 1)}"
    Stage = "${var.stage}"
    Version = "${var.version_jenkins}"
  }
}
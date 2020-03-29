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


resource "aws_instance" "jenkins_master" {
  instance_type = "t2.micro"
  ami           = "${lookup(var.aws_amis, var.aws_region)}"

  count = 1

  subnet_id              = "${random_shuffle.random_subnet.result[0]}"
  vpc_security_group_ids = ["${aws_security_group.jenkins-master.id}"]
  key_name               = "${var.KEY_NAME}"
  iam_instance_profile = "${aws_iam_instance_profile.jenkins-master.id}"

  provisioner "file" {
    source      = "script-jenkins-master.sh"
    destination = "/tmp/script-jenkins-master.sh"
}

  provisioner "file" {
    source      = "/home/ubuntu/.aws/config"
    destination = "/tmp/config"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/script-jenkins-master.sh",
      "sudo /tmp/script-jenkins-master.sh",
    ]
  }

  

  connection {
    user        = "${var.INSTANCE_USERNAME}"
    private_key = "${file("${var.PATH_TO_KEY}")}"
    host = "${self.public_dns}"
  }

  tags = {
    Name = "${format("jenkins-master-%03d", count.index + 1)}"
    Stage = "${var.stage}"
    Version = "${var.version_jenkins}"
    Jenkins = "master"
  }
}
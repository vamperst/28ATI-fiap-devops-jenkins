resource "aws_security_group" "jenkins-master" {
  vpc_id      = "${data.aws_vpc.vpc.id}"
  name        = "jenkins-master-${var.version_jenkins}-${var.stage}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 50000
    to_port     = 50000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "jenkins-master-${var.version_jenkins}-${var.stage}"
  }
}

resource "aws_iam_instance_profile" "jenkins-master" {
  name = "jenkins-master-${var.version_jenkins}-${var.stage}"
  role = "${aws_iam_role.jenkins-master-role.name}"
}

resource "aws_iam_role" "jenkins-master-role" {
  name = "jenkins-master-${var.version_jenkins}-${var.stage}"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "ec2.amazonaws.com"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}
resource "aws_iam_role_policy_attachment" "ec2-read-only-policy-attachment" {
    role = "${aws_iam_role.jenkins-master-role.name}"
    policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
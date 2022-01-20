resource "aws_instance" "ami-instance" {
  ami                         = data.aws_ami.centos7.id
  instance_type               = "t3.small"
  vpc_security_group_ids      = [aws_security_group.sg.id]

  tags                        = {
    Name                      = "${var.COMPONENT}-ami"
  }
}

resource "aws_security_group" "sg" {
  name                        = "allow_${var.COMPONENT}-ami"
  description                 = "allow_${var.COMPONENT}-ami"

  ingress {
    description               = "SSH"
    from_port                 = 22
    to_port                   = 22
    protocol                  = "tcp"
    cidr_blocks               = ["0.0.0.0/0"]
  }

  egress {
    from_port                 = 0
    to_port                   = 0
    protocol                  = "-1"
    cidr_blocks               = ["0.0.0.0/0"]
    ipv6_cidr_blocks          = ["::/0"]
  }

  tags                        = {
    Name                      = "allow_${var.COMPONENT}-ami"
  }
}

resource "null_resource" "ansible-apply" {
  provisioner "remote-exec" {
    connection {
      host                    = element(aws_instance.ami-instance.public_ip, count.index)
      user                    = jsondecode(data.aws_secretsmanager_secret_version.secrets.secret_string)["SSH_USER"]
      password                = jsondecode(data.aws_secretsmanager_secret_version.secrets.secret_string)["SSH_PASS"]
    }

    inline = [
      "sudo yum install python3-pip -y",
      "sudo pip3 install pip --upgrade",
      "sudo pip3 install ansible==4.1.0",
      "ansible-pull -i localhost, -U https://github.com/zeeshan1203/ansible.git roboshop-pull.yml -e ENV=ENV  -e COMPONENT=${var.COMPONENT} -e PAT=${jsondecode(data.aws_secretsmanager_secret_version.secrets.secret_string)["PAT"]} -e APP_VERSION=${var.APP_VERSION}"
    ]
  }
}

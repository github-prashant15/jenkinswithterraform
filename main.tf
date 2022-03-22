data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}

resource "aws_instance" "jenkins" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  associate_public_ip_address = "true"
  key_name                    = aws_key_pair.mykey.key_name
  vpc_security_group_ids      = [aws_security_group.Jenkins-SecurityGroup.id]
  subnet_id                   = var.subnet_id
  user_data                   = <<EOF
#!/bin/bash
sudo apt update -y 
sudo apt install default-jre -y
sudo apt-get install openjdk-8-jdk -y
wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo apt-key add -
sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
sudo apt install jenkins -y
sudo systemctl start jenkins
EOF
  tags = {
    Name = "${var.namespace}-server"
  }
}

resource "aws_security_group" "Jenkins-SecurityGroup" {
  name        = "${var.namespace}-sg"
  description = "this is a security group for inbound traffic"
  vpc_id      = var.vpc_id

  ingress {
    description = "this is securityGroup for jenkins port"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }

  ingress {
    description = "this is securityGroup for ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "${var.namespace}-sg"
  }
}

resource "tls_private_key" "mykey" {
  algorithm = "RSA"
  rsa_bits  = 4096
}


resource "aws_key_pair" "mykey" {
  key_name   = "${var.namespace}-id"
  public_key = tls_private_key.mykey.public_key_openssh
}
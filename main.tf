#================= Create vpc ========================#

resource "aws_vpc" "my_vpc" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = "main_vpc"
  }
}
#================= Create Internet Gateway =====================#
resource "aws_internet_gateway" "my_ngw" {
  vpc_id = aws_vpc.my_vpc.id
}
#================= Create subnet , route table , routes , Association =====================#

resource "aws_subnet" "my_subnet" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = var.subnet_cidr
  map_public_ip_on_launch = "true"
  tags = {
    Name = "my_subnet"
  }
}

resource "aws_route_table" "route_table1" {
  vpc_id = aws_vpc.my_vpc.id
}

resource "aws_route" "routes1" {
  route_table_id         = aws_route_table.route_table1.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.my_ngw.id
}

resource "aws_route_table_association" "association_1" {
  subnet_id      = aws_subnet.my_subnet.id
  route_table_id = aws_route_table.route_table1.id
}

#================= Create Security Group =====================#

resource "aws_security_group" "my_sg" {

  vpc_id = aws_vpc.my_vpc.id

  ingress { # for ssh 
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress { # for http 
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "my-sg"
  }
}

#================= Create Ec2 =====================#

resource "aws_instance" "my_instance" {
  ami                              = "ami-0dba2cb6798deb6d8"
  subnet_id                        = aws_subnet.my_subnet.id
  instance_type                    = "t2.micro"
  associate_public_ip_address = true
  security_groups         = [aws_security_group.my_sg.id]
  key_name                         = var.key_name

  provisioner "remote-exec" {
    inline = [
      "echo 'wait until SSH ready!'"
    ]
    connection {
      type        = "ssh"
      user        = var.ssh_user
      private_key = file(var.private_key_path)
      host        = aws_instance.my_instance.public_ip
    }
  }

  provisioner "local-exec" {
    command = "ansible-playbook -i ${aws_instance.my_instance.public_ip}, --private-key ${var.private_key_path} nginx.yml"
  }
}


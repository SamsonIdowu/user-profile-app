provider "aws" {
    region = "us-east-1"  
}

variable vpc_cidr_bloc {}
variable subnet_cidr_block {}
variable avail_zone {}
variable env_prefix {}
variable myip_address {}
variable public_key_location {}

resource "aws_vpc" "myapp-vpc" {
  cidr_block = var.vpc_cidr_bloc
  tags = {
    Name = "${var.env_prefix}-vpc"
  }
}

resource "aws_subnet" "myapp-subnet" {
  vpc_id     = aws_vpc.myapp-vpc.id
  cidr_block = var.subnet_cidr_block
  availability_zone = var.avail_zone
  tags = {
    Name = "${var.env_prefix}-subnet"
  }
}

resource "aws_default_route_table" "main-route-table" {
  default_route_table_id =  aws_vpc.myapp-vpc.default_route_table_id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myapp-igw.id
  }
  tags = {
    Name = "${var.env_prefix}-main-rtb"
  }

}

resource "aws_internet_gateway" "myapp-igw" {
  vpc_id     = aws_vpc.myapp-vpc.id
  tags = {
    Name = "${var.env_prefix}-igw"
  }
}
resource "aws_default_security_group" "default-sg" {
  vpc_id     = aws_vpc.myapp-vpc.id
  ingress {
    protocol = "tcp"
    from_port = 8080
    to_port = 8080
    cidr_blocks = [ "0.0.0.0/0" ]
  }
  ingress {
    protocol = "tcp"
    from_port = 22
    to_port = 22
    cidr_blocks = [ "${var.myip_address}" ]
  }
  ingress {
    protocol = "tcp"
    from_port = 3000
    to_port = 3000
    cidr_blocks = [ "0.0.0.0/0" ]
  }
  egress {
    protocol = "-1"
    from_port = 0
    to_port = 0
    cidr_blocks = [ "0.0.0.0/0" ]
    prefix_list_ids = []
  }
  tags = {
    Name = "${var.env_prefix}-default-sg"
  }
}
data "aws_ami" "latest-ubuntu-ami" {
  most_recent = true
  owners = ["amazon"]
  filter {
    name = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  } 
}
output "aws_ami_id" {
    value = data.aws_ami.latest-ubuntu-ami.id
  }

output "ec2_public_ip" {
  value = aws_instance.myapp-server.public_ip
}

resource "aws_key_pair" "ssh-key" {
  key_name = "server-ssh-key"
  public_key = file(var.public_key_location)
  
}

resource "aws_instance" "myapp-server" {
  ami = data.aws_ami.latest-ubuntu-ami.id
  instance_type = "t2.micro"

  vpc_security_group_ids = [ aws_default_security_group.default-sg.id ]
  subnet_id = aws_subnet.myapp-subnet.id
  availability_zone = var.avail_zone
  associate_public_ip_address = true
  key_name = aws_key_pair.ssh-key.key_name
  tags = {
    Name = "${var.env_prefix}-server"
  }
}
/*
resource "aws_route_table_association" "assoc-rtb-subnet" {
  subnet_id = aws_subnet.myapp-subnet.id
  route_table_id = aws_route_table.myapp-route-table.id
  
}


*/
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

# Prerequiste: Initialize AWS
provider "aws" {
  region = "us-east-1"
}

# Step 1: VPC
resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"
}

# Step 2: Private* and Public Subnets
#         * private subnet may not be used.
resource "aws_subnet" "private" {
  cidr_block              = "10.0.1.0/24"
  vpc_id                  = aws_vpc.vpc.id
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = false

  tags = {
    Name = "private-subnet"
  }
}

resource "aws_subnet" "public" {
  cidr_block              = "10.0.2.0/24"
  vpc_id                  = aws_vpc.vpc.id
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet"
  }
}

# Step 3: Security Group Configuration
resource "aws_security_group" "cc2-terraform-ansible-sg" {
  vpc_id = aws_vpc.vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow All Egress
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "vpc-igw"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-route-table"
  }
}

resource "aws_route_table_association" "public_rta" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public_rt.id
}

# Step 4: HAProxy Instance
resource "aws_instance" "haproxy" {
  #ami           = "ami-07d9b9ddc6cd8dd30"
  ami           = "ami-07d9b9ddc6cd8dd30" 
  instance_type = "t2.micro"          
  subnet_id              = aws_subnet.public.id
  security_groups        = [aws_security_group.cc2-terraform-ansible-sg.id]
  associate_public_ip_address = true # public
  tags = {
    Name = "cc2-tf-ans-haproxy"
  }
}

# Step 5: Nginx Webserver Instances
resource "aws_instance" "nginx1" {
  ami           = "ami-07d9b9ddc6cd8dd30"  
  instance_type = "t2.micro"

  subnet_id           = aws_subnet.private.id
  security_groups     = [aws_security_group.cc2-terraform-ansible-sg.id]
  associate_public_ip_address = false  # not public

  tags = {
    Name = "cc2-tf-ans-webserver1"
  }
}

resource "aws_instance" "nginx2" {
  ami           = "ami-07d9b9ddc6cd8dd30" 
  instance_type = "t2.micro"

  subnet_id           = aws_subnet.private.id
  security_groups     = [aws_security_group.cc2-terraform-ansible-sg.id]
  associate_public_ip_address = false

  tags = {
    Name = "cc2-tf-ans-webserver2"
  }
}

data "template_file" "jump_user_data" {
    template = file("jump-config.cfg")
}

# Step 6: Jump Host
resource "aws_instance" "jump" {
  ami           = "ami-07d9b9ddc6cd8dd30" 
  instance_type = "t2.micro"

  subnet_id           = aws_subnet.public.id
  user_data           = data.template_file.jump_user_data.rendered
  security_groups     = [aws_security_group.cc2-terraform-ansible-sg.id]
  associate_public_ip_address = true

  tags = {
    Name = "cc2-tf-ans-jump"
  }
}

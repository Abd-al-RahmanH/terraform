terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
 
# Configure the AWS Provider
provider "aws" {
  region = "ap-south-1"
}

# create vpc
 resource "aws_vpc" "myvpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "My-vpc"
  }
}

#PUBLIC SUBNET
resource "aws_subnet" "pubsub" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-south-1a"

  tags = {
    Name = "Public-subnet"
  }
}
#PRIVATE SUBNET
resource "aws_subnet" "prisub" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "ap-south-1b"

  tags = {
    Name = "Private-subnet"
  }
}

# Internet gateway
resource "aws_internet_gateway" "tigw" {
  vpc_id = aws_vpc.myvpc.id

  tags = {
    Name = "M-VPC-IGW"
  }
}

# public Route table
resource "aws_route_table" "pubrt" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.tigw.id
  }

  tags = {
    Name = "MY-VPC-PUB-RT"
  }
}
#PUBLIC RT ASSOCIATION
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.pubsub.id
  route_table_id = aws_route_table.pubrt.id
}

#Elastic Ip
resource "aws_eip" "myeip" {
   domain   = "vpc"
}

# NAT GATEWAY
resource "aws_nat_gateway" "tnat" {
  allocation_id = aws_eip.myeip.id
  subnet_id     = aws_subnet.pubsub.id

  tags = {
    Name = "GW NAT"
  }
}

#Private route table
resource "aws_route_table" "prirt" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.tnat.id
  }
 tags = {
    Name = "MY-VPC-PUB-RT"
  }
  }
  #PRIVATE RT ASSOCIATION
resource "aws_route_table_association" "prirtasso" {
  subnet_id      = aws_subnet.prisub.id
  route_table_id = aws_route_table.prirt.id
}
# SECURIY GROUPS
resource "aws_security_group_rule""allowall" {
  name        = "allowall"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.myvpc.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
     
  }

  ingress {
    description      = "TLS from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]

   
 
}
}
#instance lauch
resource "aws_instance" "instance1" {
    ami           = "ami-03a6eaae9938c858c"  
    instance_type = "t2.micro"
    subnet_id     = aws_subnet.pubsub.id
    security_groups = ["aws_security_group_rule.allowall.id"]
    key_name ="Laptop key"
    associate_public_ip_address =true
}

resource "aws_instance" "instance2" {
    ami           = "ami-053b0d53c279acc90"  
    instance_type = "t2.micro"
    subnet_id     = aws_subnet.prisub.id
    security_groups = ["aws_security_group_rule.allowall.id"]
    key_name ="Laptop key"
     
}

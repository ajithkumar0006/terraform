# Define provider and AWS region
provider "aws" {
  region = "us-west-2"
}

# Create VPC
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
}

# Create Internet Gateway
resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id
}

# Create VPC subnet
resource "aws_subnet" "my_subnet" {
  vpc_id                = aws_vpc.my_vpc.id
  cidr_block            = "10.0.0.0/24"
  availability_zone     = "us-west-2a"
}

# Create route table
resource "aws_route_table" "my_rt" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }
}

# Associate subnet with route table
resource "aws_route_table_association" "subnet_association" {
  subnet_id      = aws_subnet.my_subnet.id
  route_table_id = aws_route_table.my_rt.id
}

# Create security group for EC2 instances
resource "aws_security_group" "ec2_sg" {
  name        = "ec2-security-group"
  description = "Security group for EC2 instances"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create security group for the load balancer
resource "aws_security_group" "lb_sg" {
  name        = "lb-security-group"
  description = "Security group for load balancer"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create EC2 instance
resource "aws_instance" "web_instance" {
  ami           = "ami-03f65b8614a860c29"
  instance_type = "t2.micro"
  key_name      = "my-key-pair"
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  subnet_id     = aws_subnet.my_subnet.id
}

# Create load balancer
resource "aws_elb" "load_balancer" {
  name               = "my-load-balancer"
  availability_zones = ["us-west-2a", "us-west-2b", "us-west-2c"]
  security_groups    = [aws_security_group.lb_sg.id]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    target              = "HTTP:80/"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
  }
}

# Attach instances to load balancer
resource "aws_lb_target_group_attachment" "attachment" {
  target_group_arn = aws_elb.load_balancer.arn
  target_id        = aws_instance.web_instance.id
  port             = 80
}

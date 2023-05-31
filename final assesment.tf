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
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.0.0/24"
  availability_zone       = "us-west-2a"
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

# Create launch configuration
resource "aws_launch_configuration" "launch_config" {
  name          = "my-launch-config"
  image_id      = "ami-04e914639d0cca79a"  
  instance_type = "t2.micro"
  security_groups = [aws_security_group.ec2_sg.id]
  user_data          = <<-EOF
    #!/bin/bash
    # Install web server (e.g., Apache)
    yum install -y httpd git

    # Clone the GitHub repository
    git clone https://github.com/StephenDsouza90/food-ordering-system-flask /tmp/food-ordering-system

    # Copy the website files to the document root
    cp -R /tmp/food-ordering-system/* /var/www/html/

    # Start web server
    service httpd start
    chkconfig httpd on
  EOF
}

# Create load balancer
resource "aws_elb" "load_balancer" {
  name               = "my-load-balancer"
  availability_zones = ["us-west-2a", "us-west-2b", "us-west-2c"]

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

# Create auto scaling group
resource "aws_autoscaling_group" "autoscaling_group" {
  name                 = "my-autoscaling-group"
  min_size             = 1
  max_size             = 3
  desired_capacity     = 1
  launch_configuration = aws_launch_configuration.launch_config.name
  vpc_zone_identifier  = [aws_subnet.my_subnet.id]
}

# Create SNS topic
resource "aws_sns_topic" "sns_topic" {
  name = "my-sns-topic"
}

# Create SNS subscription
resource "aws_sns_topic_subscription" "sns_subscription" {
  topic_arn = aws_sns_topic.sns_topic.arn
  protocol  = "email"
  endpoint  = "sheela@onedatasoftware.com"  
}

# Create CloudWatch alarm
resource "aws_cloudwatch_metric_alarm" "instance_alarm" {
  alarm_name          = "my-instance-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric checks CPU utilization of the EC2 instance"
  alarm_actions       = [aws_sns_topic.sns_topic.arn]
}

aws_region = "ap-south-1"

project_name = "myapp-prod"
environment  = "prod"

vpc_cidr = "20.0.0.0/16"

public_subnets_cidr = [
  "20.0.1.0/24",
  "20.0.2.0/24",
  "20.0.3.0/24"
]

private_subnets_cidr = [
  "20.0.10.0/24",
  "20.0.11.0/24",
  "20.0.12.0/24"
]

azs = [
  "ap-south-1a",
  "ap-south-1b",
  "ap-south-1c"
]

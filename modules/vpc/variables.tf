variable "vpc_cidr" {}
variable "public_subnets_cidr" { type = list(string) }
variable "private_subnets_cidr" { type = list(string) }
variable "azs" { type = list(string) }
variable "environment" {}
variable "project_name" {}
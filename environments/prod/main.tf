provider "aws" {
  region = "ap-south-1"
}

module "vpc" {
  source               = "../../modules/vpc"
  project_name         = "myapp-prod"
  environment          = "prod"
  vpc_cidr             = "192.168.0.0/16"
  public_subnets_cidr  = ["192.168.1.0/24", "192.168.2.0/24", "192.168.3.0/24"]
  private_subnets_cidr = ["192.168.10.0/24", "192.168.11.0/24", "192.168.12.0/24"]
  azs                  = ["ap-south-1a", "ap-south-1b", "ap-south-1c"]
}

module "security" {
  source       = "../../modules/security"
  project_name = "myapp-prod"
  vpc_id       = module.vpc.vpc_id
}

module "storage" {
  source       = "../../modules/storage"
  project_name = "myapp-prod"
  environment  = "prod"
}
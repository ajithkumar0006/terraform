provider "aws" {
  region = "ap-south-1"
}

module "vpc" {
  source               = "../../modules/vpc"
  project_name         = "myapp-dev"
  environment          = "dev"
  vpc_cidr             = "10.0.0.0/16"
  public_subnets_cidr  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets_cidr = ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]
  azs                  = ["ap-south-1a", "ap-south-1b", "ap-south-1c"]
}

module "security" {
  source       = "../../modules/security"
  project_name = "myapp-dev"
  vpc_id       = module.vpc.vpc_id
}

module "storage" {
  source       = "../../modules/storage"
  project_name = "myapp-dev"
  environment  = "dev"
}
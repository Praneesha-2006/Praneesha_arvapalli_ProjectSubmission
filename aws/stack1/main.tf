provider "aws" {
  region = "us-west-2"  # Change this to your desired region
  }

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "bedrock-poc-vpc"
  cidr = "172.31.0.0/16"

  azs = ["us-west-2a", "us-west-2c"]
  public_subnets  = ["172.31.101.0/24", "172.31.102.0/24", "172.31.103.0/24"]
  private_subnets = ["172.31.1.0/24",   "172.31.2.0/24",   "172.31.3.0/24"]
  enable_nat_gateway = true
  single_nat_gateway = true

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

module "aurora_serverless" {
  source = "../modules/database"

  cluster_identifier = "my-aurora-serverless"
  vpc_id             = module.vpc.vpc_id 
  subnet_ids         = module.vpc.private_subnets

  # Optionally override other defaults
  database_name    = "database1"
  master_username  = "postgres"
  max_capacity     = 128
  min_capacity     = 0.5
  allowed_cidr_blocks = ["172.31.0.0/16"] 
  
}

data "aws_caller_identity" "current" {}

locals {
  bucket_name = "query-doc-bucket"
}

module "s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 3.0"

  bucket = local.bucket_name
  acl    = "private"
  force_destroy = true

  control_object_ownership = true
  object_ownership         = "BucketOwnerPreferred"

  versioning = {
    enabled = true
  }

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

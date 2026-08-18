terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region  = "us-east-1"
  profile = "demo-sa"

  default_tags {
    tags = {
      Project     = "taskmanager"
      Environment = "demo"
      ManagedBy   = "terraform"
    }
  }
}

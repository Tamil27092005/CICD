terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Local state by default. For persistent state across Jenkins workspaces,
  # switch to a remote backend, e.g.:
  #
  # backend "s3" {
  #   bucket = "your-tfstate-bucket"
  #   key    = "cicd-python-app/terraform.tfstate"
  #   region = "ap-south-1"
  # }
}

provider "aws" {
  region = var.aws_region
}

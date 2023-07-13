terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      # explicit dependency versions prevent breakage from new releases 
      version = "4.52.0"
    }
  }
  backend "s3" {
    # values passed from CLI
  }
}

# default aws provider that uses aws credentials of your current env
provider "aws" {
  default_tags {
    tags = var.tags
  }
}

# us-east-1 provider
provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
  # default tags get applied to all resources that accept tags
  default_tags {
    tags = var.tags
  }
}

# us-east-2 provider
provider "aws" {
  alias  = "us-east-2"
  region = "us-east-2"
  # default tags get applied to all resources that accept tags
  default_tags {
    tags = var.tags
  }
}
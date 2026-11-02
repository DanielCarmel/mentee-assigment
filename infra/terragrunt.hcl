locals {
  aws_region              = "eu-west-2"
  account_id              = "030454160336"
  github_org              = "DanielCarmel"
  github_repo             = "mentee-assigment"
  app_name                = "hello-world"
  permissions_boundary_arn = "arn:aws:iam::030454160336:policy/candidate-exam-boundary"

  common_tags = {
    Project   = "mentee-assignment"
    ManagedBy = "terragrunt"
  }
}

# Generate the AWS provider for every unit.
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = "${local.aws_region}"

  default_tags {
    tags = {
      Project   = "mentee-assignment"
      ManagedBy = "terragrunt"
    }
  }
}
EOF
}

# Pin Terraform + provider versions for every unit.
generate "versions" {
  path      = "versions.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}
EOF
}

# Local state — fine for an ephemeral exam account.
# Production: swap for an S3 backend with DynamoDB locking.
remote_state {
  backend = "local"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    path = "${get_terragrunt_dir()}/terraform.tfstate"
  }
}

inputs = {
  aws_region               = local.aws_region
  account_id               = local.account_id
  github_org               = local.github_org
  github_repo              = local.github_repo
  app_name                 = local.app_name
  permissions_boundary_arn = local.permissions_boundary_arn
  common_tags              = local.common_tags
}

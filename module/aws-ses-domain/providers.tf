terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0.0, < 7.0.0"
    }
  }
}

# The `provider "aws"` block is intentionally NOT declared here. This module
# is consumed via Terragrunt, which generates the provider from
# `iac.homelab-live-infra/_providers/aws.hcl`. Declaring one here would
# collide with that.

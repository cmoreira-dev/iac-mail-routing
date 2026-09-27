terraform {
  required_version = ">= 1.10.0"

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.0"
    }
  }
}

# The `provider "cloudflare"` block is intentionally NOT declared here. This
# module is consumed via Terragrunt, which generates the provider from
# `iac.homelab-live-infra/_providers/cloudflare.hcl` (API token injected via
# TF_VAR_cloudflare_api_token, never committed). Declaring one here would
# collide with that.

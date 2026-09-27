# iac-mail-routing

Reusable Terraform module: Cloudflare Email Routing (inbound) + Amazon SES
(outbound transactional mail) + the Cloudflare DNS records that tie the two
together. Not tied to any one product — every domain, address and identifier
is passed in via `inputs` from the Terragrunt unit that consumes it.

Four independent submodules, each consumed separately via Terragrunt's
`//<path>` source syntax:

| Submodule | Provider | Owns |
|---|---|---|
| `module/cloudflare-email-routing` | Cloudflare | MX + Cloudflare's own SPF on the root domain, destination addresses, per-address rules, catch-all |
| `module/cloudflare-mail-dns` | Cloudflare | DKIM CNAMEs, MAIL FROM subdomain's MX + SPF, DMARC TXT — all for outbound SES mail |
| `module/aws-ses-domain` | AWS | SES domain identity (Easy DKIM), custom MAIL FROM domain, configuration set, bounce/complaint/delivery events via SNS -> SQS |
| `module/aws-ses-smtp-user` | AWS | One IAM user + SSM-stored credentials per caller (API vs. human SMTP), each scoped to a single SES action |

`cloudflare-email-routing` and `cloudflare-mail-dns` are deliberately separate
modules even though both touch the same zone: the first owns the root
domain's inbound MX/SPF, the second owns the mail subdomain's outbound
records. Keeping them apart means a Terragrunt unit that only needs inbound
routing (no SES yet) doesn't have to pass SES outputs it doesn't have.

Right now all four submodules are empty scaffolding (`providers.tf` pinning
versions + `variables.tf` declaring the intended interface) — the resources
themselves land in later phases. `terraform validate` (via `tofu validate`)
passes on each as-is; there is nothing to plan or apply yet.

## Usage

Consumed via Terragrunt from `infra-as-code/iac.homelab-live-infra`, one unit
per submodule, pointing `source` at the submodule path:

```hcl
# iac.homelab-live-infra/cloudflare/email-routing/terragrunt.hcl (example)
include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "account" {
  path = find_in_parent_folders("account.hcl")
}

terraform {
  source = "git::https://github.com/cmoreira-dev/iac-mail-routing.git//module/cloudflare-email-routing?ref=main"
}

inputs = {
  zone_id = "..."
  addresses = {
    contato = "you@gmail.com"
  }
}
```

Product-specific values (domain, addresses, SSM parameter paths) belong in
that unit's `inputs`, never in this module.

## Requirements

- `hashicorp/aws` `>= 6.0.0, < 7.0.0`
- `cloudflare/cloudflare` `~> 5.0` — v5 renamed several resources relative to
  v4; follow the v5 docs when implementing each submodule.

## Pending

- [ ] Implement `cloudflare-email-routing` resources (a later phase).
- [ ] Implement `aws-ses-domain`, `aws-ses-smtp-user` and
      `cloudflare-mail-dns` resources (a later phase).
- [ ] Once tagging starts, pin consumers' `?ref=` to a released tag instead
      of `main`.

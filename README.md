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

All four submodules are implemented. `terraform validate` (via `tofu
validate`) passes on all four modules.

### `cloudflare-email-routing`

Given `domain_name` (the zone is looked up from it — never pass a raw zone
ID), `addresses` (local-part -> a single destination mailbox) and a
catch-all policy:

- `cloudflare_email_routing_dns` enables Email Routing on the zone — this is
  the resource that makes Cloudflare add the MX + its own SPF include, no
  `cloudflare_dns_record` needed for that part.
- One `cloudflare_email_routing_address` per distinct destination mailbox
  (deduped across `addresses` and the catch-all destination, if forwarding).
- One `cloudflare_email_routing_rule` per entry in `addresses`, matching the
  full `local-part@domain` and forwarding to its destination.
- One `cloudflare_email_routing_catch_all` for anything not explicitly
  listed — `drop` or `forward`, via `catch_all_action`.

**Cloudflare does not support forwarding one address to more than one
destination.** A forward action with more than one value is rejected
("forward action must contain exactly one destination"), and so is a second
rule matching the same address ("Duplicated Zone rule") — confirmed live
against the real API, not just the docs. If several people need the same
mail, route it to one mailbox and forward/distribute from there.

**Manual step Terraform cannot do:** Cloudflare emails every new destination
address a confirmation link. Until that's clicked, the address (and any rule
pointing at it) stays `unverified` and mail is not actually delivered. Check
the `address_verification_status` output after apply.

## Usage

Consumed via Terragrunt from `<live-infra-repo>`, one unit
per submodule, pointing `source` at the submodule path:

```hcl
# <live-infra-repo>/cloudflare/email-routing/terragrunt.hcl (example)
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
  domain_name = "example.com"
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

- [x] Implement `aws-ses-domain` resources and expose the DKIM tokens and
      custom MAIL FROM MX target consumed by `cloudflare-mail-dns`.
- [x] Implement `aws-ses-smtp-user` and `cloudflare-mail-dns` resources.
- [ ] Once tagging starts, pin consumers' `?ref=` to a released tag instead
      of `main`.

# Inbound email routing: enables Email Routing on the zone (Cloudflare adds
# the MX + its own SPF include automatically via this resource — no
# `cloudflare_dns_record` needed for that part), verifies/creates the
# destination mailboxes, and adds one forwarding rule per address plus a
# catch-all.
#
# Manual step, outside Terraform: Cloudflare emails each new destination
# address to confirm it. The address (and any rule pointing at it) stays
# "unverified" — mail is not actually delivered — until that link is
# clicked. `terraform apply` cannot do this for you.

data "cloudflare_zone" "this" {
  filter = { name = var.domain_name }
}

locals {
  zone_id = data.cloudflare_zone.this.id

  # Cloudflare rejects a forward action with more than one destination
  # ("forward action must contain exactly one destination"), even though a
  # single local-part in `addresses` may list several. So one rule is created
  # per (local-part, destination) pair instead of per local-part — all
  # matching the same "to" address, each forwarding to just one mailbox.
  rule_pairs = merge([
    for local_part, destinations in var.addresses : {
      for destination in destinations : "${local_part}::${destination}" => {
        local_part  = local_part
        destination = destination
      }
    }
  ]...)
}

resource "cloudflare_email_routing_dns" "this" {
  # `name` is deliberately omitted: the API rejects it when set to the zone's
  # own apex domain ("must be a subdomain of <domain>") — zone_id alone is
  # enough to enable routing on the root domain.
  zone_id = local.zone_id
}

resource "cloudflare_email_routing_address" "destination" {
  for_each = toset(distinct(concat(
    flatten(values(var.addresses)),
    var.catch_all_action == "forward" ? var.catch_all_destinations : [],
  )))

  account_id = data.cloudflare_zone.this.account.id
  email      = each.value
}

resource "cloudflare_email_routing_rule" "address" {
  for_each = local.rule_pairs

  zone_id  = local.zone_id
  name     = "${each.value.local_part}@${data.cloudflare_zone.this.name} -> ${each.value.destination}"
  enabled  = true
  priority = 10 + index(sort(keys(local.rule_pairs)), each.key)

  matchers = [{
    type  = "literal"
    field = "to"
    value = "${each.value.local_part}@${data.cloudflare_zone.this.name}"
  }]

  actions = [{
    type  = "forward"
    value = [each.value.destination]
  }]

  depends_on = [
    cloudflare_email_routing_dns.this,
    cloudflare_email_routing_address.destination,
  ]
}

resource "cloudflare_email_routing_catch_all" "this" {
  zone_id = local.zone_id
  name    = "catch-all"
  enabled = true

  matchers = [{ type = "all" }]

  actions = [{
    # Cloudflare's catch-all action supports at most one forward destination,
    # unlike a regular routing rule.
    type  = var.catch_all_action
    value = var.catch_all_action == "forward" ? [var.catch_all_destinations[0]] : []
  }]

  depends_on = [cloudflare_email_routing_dns.this]
}

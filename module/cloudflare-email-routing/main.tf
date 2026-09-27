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
}

resource "cloudflare_email_routing_dns" "this" {
  # `name` is deliberately omitted: the API rejects it when set to the zone's
  # own apex domain ("must be a subdomain of <domain>") — zone_id alone is
  # enough to enable routing on the root domain.
  zone_id = local.zone_id
}

resource "cloudflare_email_routing_address" "destination" {
  for_each = toset(distinct(concat(
    values(var.addresses),
    var.catch_all_action == "forward" ? [var.catch_all_destination] : [],
  )))

  account_id = data.cloudflare_zone.this.account.id
  email      = each.value
}

resource "cloudflare_email_routing_rule" "address" {
  for_each = var.addresses

  zone_id  = local.zone_id
  name     = "${each.key}@${data.cloudflare_zone.this.name} -> ${each.value}"
  enabled  = true
  priority = 10 + index(sort(keys(var.addresses)), each.key)

  matchers = [{
    type  = "literal"
    field = "to"
    value = "${each.key}@${data.cloudflare_zone.this.name}"
  }]

  actions = [{
    # Cloudflare rejects more than one value here ("forward action must
    # contain exactly one destination"), and also rejects a second rule
    # matching the same address ("Duplicated Zone rule") — so one address
    # can only ever forward to a single destination.
    type  = "forward"
    value = [each.value]
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
    type  = var.catch_all_action
    value = var.catch_all_action == "forward" ? [var.catch_all_destination] : []
  }]

  depends_on = [cloudflare_email_routing_dns.this]
}

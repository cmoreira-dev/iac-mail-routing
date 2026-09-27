# DNS records that back outbound SES mail: the 3 DKIM CNAMEs, the MAIL FROM
# subdomain's MX + SPF, and the domain's DMARC TXT record. Deliberately
# separate from cloudflare-email-routing, which owns the root domain's own MX
# + SPF for inbound mail — the two must never collide on the same records.
# The DKIM tokens and MAIL FROM target are outputs from aws-ses-domain and are
# passed into this module by the consuming Terragrunt unit.

data "cloudflare_zone" "this" {
  filter = { name = var.domain_name }
}

locals {
  zone_id = data.cloudflare_zone.this.id
}

resource "cloudflare_dns_record" "dkim" {
  for_each = toset(var.dkim_tokens)

  zone_id = local.zone_id
  name    = "${each.value}._domainkey"
  type    = "CNAME"
  ttl     = 300
  content = "${each.value}.dkim.amazonses.com"
  proxied = false
}

resource "cloudflare_dns_record" "mail_from_mx" {
  zone_id = local.zone_id
  name    = var.mail_from_subdomain
  type    = "MX"
  ttl     = 300
  content = var.ses_mail_from_mx
  priority = 10
}

resource "cloudflare_dns_record" "mail_from_spf" {
  zone_id = local.zone_id
  name    = var.mail_from_subdomain
  type    = "TXT"
  ttl     = 300
  content = "\"v=spf1 include:amazonses.com ~all\""
}

resource "cloudflare_dns_record" "dmarc" {
  zone_id = local.zone_id
  name    = "_dmarc"
  type    = "TXT"
  ttl     = 300
  content = "\"v=DMARC1; p=${var.dmarc_policy}; rua=mailto:${var.dmarc_report_address}\""
}

# DNS records that back outbound SES mail: the 3 DKIM CNAMEs, the MAIL FROM
# subdomain's MX + SPF, and the domain's DMARC TXT record. Deliberately
# separate from cloudflare-email-routing, which owns the root domain's own MX
# + SPF for inbound mail — the two must never collide on the same records.
# Resources land here in a later phase, consuming SES's outputs as inputs.

variable "domain_name" {
  description = "Domain to enable Email Routing on, e.g. \"example.com\" — the zone ID is looked up from this, so callers never need to hardcode it"
  type        = string
}

variable "addresses" {
  description = "Map of local-part (without the domain) to a single destination mailbox, e.g. { contato = \"you@gmail.com\" }. One routing rule is created per entry. Cloudflare Email Routing does not support forwarding one address to more than one destination — neither in a single rule nor via multiple rules on the same matcher (\"Duplicated Zone rule\")."
  type        = map(string)
}

variable "catch_all_action" {
  description = "What happens to mail for addresses not listed in `addresses` — \"drop\" or \"forward\""
  type        = string
  default     = "drop"
}

variable "catch_all_destination" {
  description = "Destination mailbox for the catch-all rule when catch_all_action is \"forward\" (ignored otherwise)"
  type        = string
  default     = null
}

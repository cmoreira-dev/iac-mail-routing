variable "domain_name" {
  description = "Domain to enable Email Routing on, e.g. \"example.com\" — the zone ID is looked up from this, so callers never need to hardcode it"
  type        = string
}

variable "addresses" {
  description = "Map of local-part (without the domain) to one or more destination mailboxes, e.g. { contato = [\"you@gmail.com\", \"someone-else@gmail.com\"] }. One routing rule is created per entry, forwarding to every listed destination."
  type        = map(list(string))
}

variable "catch_all_action" {
  description = "What happens to mail for addresses not listed in `addresses` — \"drop\" or \"forward\""
  type        = string
  default     = "drop"
}

variable "catch_all_destinations" {
  description = "Destination mailboxes for the catch-all rule when catch_all_action is \"forward\" (ignored otherwise)"
  type        = list(string)
  default     = []
}

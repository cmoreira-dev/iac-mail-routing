# Interface for a later phase — declared now so consumers can already see the
# contract this module will expose. No resource reads these yet.

variable "zone_id" {
  description = "Cloudflare zone ID to enable Email Routing on"
  type        = string
}

variable "addresses" {
  description = "Map of local-part (without the domain) to destination mailbox, e.g. { contato = \"you@gmail.com\" }. One routing rule is created per entry."
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

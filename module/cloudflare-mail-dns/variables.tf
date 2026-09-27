# Interface for a later phase — declared now so consumers can already see the
# contract this module will expose. No resource reads these yet.

variable "zone_id" {
  description = "Cloudflare zone ID to create the mail DNS records on"
  type        = string
}

variable "mail_from_subdomain" {
  description = "Subdomain used as the SES MAIL FROM domain, e.g. \"mail\" for mail.example.com"
  type        = string
}

variable "dkim_tokens" {
  description = "The 3 Easy DKIM tokens from the aws-ses-domain module's output, used to build the <token>._domainkey CNAME records"
  type        = list(string)
}

variable "ses_mail_from_mx" {
  description = "MX target for the MAIL FROM subdomain, e.g. feedback-smtp.<region>.amazonses.com"
  type        = string
}

variable "dmarc_policy" {
  description = "DMARC policy (\"none\", \"quarantine\" or \"reject\") — start at \"none\" and tighten after a clean reporting period"
  type        = string
  default     = "none"
}

variable "dmarc_report_address" {
  description = "Mailbox that receives DMARC aggregate reports (rua=)"
  type        = string
}

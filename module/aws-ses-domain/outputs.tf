output "dkim_tokens" {
  description = "Easy DKIM tokens used to create the domainkey CNAME records"
  value       = aws_sesv2_email_identity.this.dkim_signing_attributes[0].tokens
}

output "mail_from_mx" {
  description = "MX target for the custom MAIL FROM subdomain"
  value       = "feedback-smtp.${data.aws_region.current.region}.amazonses.com"
}

output "identity_arn" {
  description = "ARN of the SES domain identity"
  value       = aws_sesv2_email_identity.this.arn
}

output "configuration_set_arn" {
  description = "ARN of the SES configuration set"
  value       = aws_sesv2_configuration_set.this.arn
}

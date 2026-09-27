# Interface for a later phase — declared now so consumers can already see the
# contract this module will expose. No resource reads these yet.

variable "domain_name" {
  description = "Domain to verify as an SES identity, e.g. \"example.com\""
  type        = string
}

variable "mail_from_subdomain" {
  description = "Subdomain used as the custom MAIL FROM domain, e.g. \"mail\" for mail.example.com"
  type        = string
}

variable "configuration_set_name" {
  description = "Name of the SES configuration set for transactional mail"
  type        = string
}

variable "sns_topic_name" {
  description = "Name of the SNS topic receiving bounce/complaint/delivery events"
  type        = string
}

variable "sqs_queue_name" {
  description = "Name of the SQS queue subscribed to the SNS topic, polled by the consuming API"
  type        = string
}

# SES domain identity (SESv2) with Easy DKIM, a custom MAIL FROM domain, a
# configuration set with the suppression list enabled, and bounce/complaint/
# delivery events routed to SNS -> SQS (so the consuming API can poll a queue
# instead of exposing a public webhook endpoint). This module's outputs feed
# cloudflare-mail-dns's inputs.

data "aws_region" "current" {}

resource "aws_sesv2_configuration_set" "this" {
  configuration_set_name = var.configuration_set_name

  reputation_options {
    reputation_metrics_enabled = true
  }

  sending_options {
    sending_enabled = true
  }

  suppression_options {
    suppressed_reasons = ["BOUNCE", "COMPLAINT"]
  }
}

resource "aws_sesv2_email_identity" "this" {
  email_identity         = var.domain_name
  configuration_set_name = aws_sesv2_configuration_set.this.configuration_set_name
}

resource "aws_sesv2_email_identity_mail_from_attributes" "this" {
  email_identity = aws_sesv2_email_identity.this.email_identity

  behavior_on_mx_failure = "USE_DEFAULT_VALUE"
  mail_from_domain       = "${var.mail_from_subdomain}.${var.domain_name}"
}

resource "aws_sns_topic" "this" {
  name = var.sns_topic_name
}

resource "aws_sqs_queue" "this" {
  name = var.sqs_queue_name
}

resource "aws_sqs_queue_policy" "allow_sns" {
  queue_url = aws_sqs_queue.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowSESConfigSetSNSTopic"
      Effect    = "Allow"
      Principal = { Service = "sns.amazonaws.com" }
      Action    = "sqs:SendMessage"
      Resource  = aws_sqs_queue.this.arn
      Condition = {
        ArnEquals = { "aws:SourceArn" = aws_sns_topic.this.arn }
      }
    }]
  })
}

resource "aws_sns_topic_subscription" "sqs" {
  topic_arn = aws_sns_topic.this.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.this.arn
}

resource "aws_sesv2_configuration_set_event_destination" "sns" {
  configuration_set_name = aws_sesv2_configuration_set.this.configuration_set_name
  event_destination_name = "bounce-complaint-delivery"

  event_destination {
    enabled              = true
    matching_event_types = ["BOUNCE", "COMPLAINT", "DELIVERY"]

    sns_destination {
      topic_arn = aws_sns_topic.this.arn
    }
  }

  depends_on = [aws_sqs_queue_policy.allow_sns, aws_sns_topic_subscription.sqs]
}

# SES domain identity (SESv2) with Easy DKIM, a custom MAIL FROM domain, a
# configuration set with the suppression list enabled, and bounce/complaint/
# delivery events routed to SNS -> SQS (so the consuming API can poll a queue
# instead of exposing a public webhook endpoint). Resources land here in a
# later phase; this module's outputs feed cloudflare-mail-dns's inputs.

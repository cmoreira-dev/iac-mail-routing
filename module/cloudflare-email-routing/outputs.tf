output "address_verification_status" {
  description = "verified/unverified per destination mailbox — unverified means Cloudflare's confirmation email hasn't been clicked yet, and mail to it is not actually delivered"
  value       = { for email, addr in cloudflare_email_routing_address.destination : email => addr.status }
}

output "zone_name" {
  description = "Resolved domain name for the given zone_id, echoed for convenience"
  value       = data.cloudflare_zone.this.name
}

output "ssm_parameter_names" {
  description = "SSM parameter name containing each user's SES credentials"
  value       = { for key, parameter in aws_ssm_parameter.credentials : key => parameter.name }
}

output "iam_user_arns" {
  description = "IAM user ARN per logical user key"
  value       = { for key, user in aws_iam_user.this : key => user.arn }
}

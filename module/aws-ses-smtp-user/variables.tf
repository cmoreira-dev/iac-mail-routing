variable "users" {
  description = "Map of logical user key to its config. Each becomes one IAM user + access key, scoped to one SES action, with its credentials written to SSM."
  type = map(object({
    iam_user_name         = string
    ses_action            = string # e.g. "ses:SendEmail" or "ses:SendRawEmail"
    ssm_parameter_path    = string # e.g. "/product/ses/api/"
    ses_identity_arn      = string
    configuration_set_arn = optional(string)
    sqs_consume_queue_arn = optional(string) # if set, the user may also read/delete messages from this queue (bounce/complaint worker)
  }))

  validation {
    condition = alltrue([
      for user in values(var.users) : contains(["ses:SendEmail", "ses:SendRawEmail"], user.ses_action)
    ])
    error_message = "ses_action must be ses:SendEmail or ses:SendRawEmail."
  }
}

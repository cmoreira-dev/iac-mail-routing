# Interface for a later phase — declared now so consumers can already see the
# contract this module will expose. No resource reads these yet.

variable "users" {
  description = "Map of logical user key to its config. Each becomes one IAM user + access key, scoped to one SES action, with its credentials written to SSM."
  type = map(object({
    iam_user_name         = string
    ses_action            = string # e.g. "ses:SendEmail" or "ses:SendRawEmail"
    ssm_parameter_path    = string # e.g. "/product/ses/api/"
    ses_identity_arn      = string
    configuration_set_arn = optional(string)
  }))
}

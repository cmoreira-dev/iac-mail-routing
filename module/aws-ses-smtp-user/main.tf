# One IAM user per caller (e.g. the transactional API vs. a human's Gmail
# "send mail as"), each scoped to only the SES action it needs, with its
# credentials written to SSM as SecureString. Access keys still end up in
# Terraform state (unavoidable for aws_iam_access_key), so the state bucket's
# encryption and restricted access carry real weight here.

resource "aws_iam_user" "this" {
  for_each = var.users

  name = each.value.iam_user_name
}

resource "aws_iam_access_key" "this" {
  for_each = var.users

  user = aws_iam_user.this[each.key].name
}

resource "aws_iam_user_policy" "ses" {
  for_each = var.users

  name = "${each.value.iam_user_name}-ses-send"
  user = aws_iam_user.this[each.key].name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "AllowScopedSESSend"
      Effect = "Allow"
      Action = each.value.ses_action
      Resource = compact([
        each.value.ses_identity_arn,
        try(each.value.configuration_set_arn, null),
      ])
    }]
  })
}

resource "aws_ssm_parameter" "credentials" {
  for_each = var.users

  name        = each.value.ssm_parameter_path
  description = "SES credentials for ${each.value.iam_user_name}"
  type        = "SecureString"
  value = jsonencode({
    access_key_id     = aws_iam_access_key.this[each.key].id
    secret_access_key = aws_iam_access_key.this[each.key].secret
    smtp_username     = aws_iam_access_key.this[each.key].id
    smtp_password     = aws_iam_access_key.this[each.key].ses_smtp_password_v4
  })

  lifecycle {
    replace_triggered_by = [aws_iam_access_key.this[each.key].id]
  }
}

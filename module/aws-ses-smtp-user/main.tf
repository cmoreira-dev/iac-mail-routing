# One IAM user per caller (e.g. the transactional API vs. a human's Gmail
# "send mail as"), each scoped to only the SES action it needs, with its
# credentials written to SSM as SecureString. Access keys still end up in
# Terraform state (unavoidable for aws_iam_access_key), so the state bucket's
# encryption and restricted access carry real weight here.
# Resources land here in a later phase.

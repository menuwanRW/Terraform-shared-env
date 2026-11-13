output "state_bucket" { value = aws_s3_bucket.state.id }
output "state_kms_key_arn" { value = aws_kms_key.state.arn }
output "ecr_repository_url" { value = aws_ecr_repository.app.repository_url }
output "ci_role_arns" { value = { for k, r in aws_iam_role.ci : k => r.arn } }

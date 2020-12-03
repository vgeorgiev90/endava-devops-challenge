output "policy_arn" {
	value = aws_dlm_lifecycle_policy.backups.arn
}

output "policy_id" {
	value = aws_dlm_lifecycle_policy.backups.id
}

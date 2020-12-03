output "access_key" {
	value = aws_iam_access_key.scalr.id
}

output "secret_access_key" {
	value = aws_iam_access_key.scalr.secret
}

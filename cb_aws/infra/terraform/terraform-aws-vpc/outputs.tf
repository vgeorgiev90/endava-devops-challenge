output "vpc_id" {
  value = aws_vpc.cb_vpc.id
}

output "private_subnet" {
  value = aws_subnet.private.*.id
}

output "db_private_subnet" {
  value = aws_subnet.db_private.*.id
}

output "rmq_private_subnet" {
  value = aws_subnet.rmq_private.*.id
}

output "public" {
  value = aws_subnet.public.*.id
}

output "es_private_subnet" {
  value = aws_subnet.elastic_private.*.id
}

output "available_zones" {
  value = aws_subnet.public.*.availability_zone
}

output "security_group_generic" {
  value = aws_security_group.generic.id
}

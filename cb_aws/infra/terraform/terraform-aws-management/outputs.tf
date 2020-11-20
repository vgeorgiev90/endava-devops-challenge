output "lb_dns" {
	value = aws_lb.vpn.dns_name
}

output "generic_security_group_id" {
	value = aws_security_group.generic.id
}

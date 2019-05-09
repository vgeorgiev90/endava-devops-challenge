output "master-ip" {
    description = "Master public IP"
    value = "${aws_instance.master.public_ip},${aws_instance.master.private_dns},${aws_instance.master.private_ip}"
}

output "worker1-ip" {
    description = "Master public IP"
    value = "${aws_instance.worker1.public_ip},${aws_instance.worker1.private_dns},${aws_instance.worker1.private_ip}"
}

output "worker2-ip" {
    description = "Master public IP"
    value = "${aws_instance.worker2.public_ip},${aws_instance.worker2.private_dns},${aws_instance.worker2.private_ip}"
}


output "master-ip" {
    description = "Master public IP"
    value = "${aws_instance.master.public_ip}"
}

output "worker1-ip" {
    description = "Master public IP"
    value = "${aws_instance.worker1.public_ip}"
}

output "worker2-ip" {
    description = "Master public IP"
    value = "${aws_instance.worker2.public_ip}"
}


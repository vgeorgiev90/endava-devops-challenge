output "master-ip" {
    description = "Master public IP"
    value = "${aws_instance.master.public_ip},${aws_instance.master.private_dns},${aws_instance.master.private_ip}"
}

output "workers-public_ips" {
    description = "Worker public IP"
    value = ["${aws_instance.worker.*.public_ip}"]
}

output "workers-private_ips" {
    description = "Worker private IP"
    value = ["${aws_instance.worker.*.private_ip}"]
}

output "workers-private_dns" {
    description = "Worker private DNS"
    value = ["${aws_instance.worker.*.private_dns}"]
}



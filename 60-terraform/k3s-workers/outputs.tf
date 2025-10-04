output "aws_worker_public_ip" {
  description = "Public IPv4 address of the AWS-based worker node."
  value       = aws_instance.k3s_worker.public_ip
}

output "aws_worker_public_dns" {
  description = "Public DNS name of the AWS-based worker node."
  value       = aws_instance.k3s_worker.public_dns
}

output "onprem_worker_ip" {
  description = "Discovered IPv4 address of the libvirt worker (requires DHCP lease)."
  value       = libvirt_domain.worker.network_interface[0].addresses
}

output "rendered_cloud_init" {
  description = "Local path to the rendered cloud-init file used for the on-prem worker."
  value       = local_file.cloud_init.filename
  sensitive   = true
}

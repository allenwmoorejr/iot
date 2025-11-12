output "cloud_worker_public_ip" {
  value       = aws_instance.cloud_worker.public_ip
  description = "Public IP of the EC2 worker"
}


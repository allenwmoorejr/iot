output "networking_namespace" {
  value = try(kubernetes_namespace.networking.metadata[0].name, null)
}

output "external_dns_mode" {
  value = var.external_dns_provider
}

output "metallb_pool" {
  value = var.metallb_address_pool
}

output "grafana_url" {
  value       = "https://grafana.${var.domain_name}"
  description = "Available if monitoring_enabled and DNS points to Traefik LB."
}

output "cloud_worker_public_ip" {
  value       = try(aws_instance.cloud_worker.public_ip, null)
  description = "Public IP of the AWS cloud worker (if created)."
}


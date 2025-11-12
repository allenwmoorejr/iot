# ---------------------------
# Core K3s / Cluster
# ---------------------------
variable "k3s_url" {
  type        = string
  description = "K3s API endpoint (https://VIP:6443)"
}

variable "k3s_token" {
  type        = string
  description = "K3s join token from control-plane node"
  sensitive   = true
}

variable "kubeconfig_path" {
  type        = string
  description = "Local kubeconfig path"
  default     = "~/.kube/config"
}

variable "cluster_name" {
  type        = string
  description = "Human-friendly cluster name"
  default     = "smart-kube"
}

variable "cluster_lan_cidr" {
  type        = string
  description = "Home LAN CIDR for allow-lists"
  default     = "192.168.50.0/24"
}

# ---------------------------
# AWS
# ---------------------------
variable "aws_profile" {
  type    = string
  default = "default"
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "aws_key_name" {
  type        = string
  description = "Existing EC2 key pair name"
}

variable "aws_allowed_cidr" {
  type        = string
  description = "CIDR allowed into security groups (your /32 or LAN/VPN CIDR)"
}

variable "aws_vpc_cidr" {
  type    = string
  default = "10.42.0.0/16"
}

variable "aws_public_subnets" {
  type    = list(string)
  default = ["10.42.1.0/24", "10.42.2.0/24"]
}

variable "aws_private_subnets" {
  type    = list(string)
  default = ["10.42.101.0/24", "10.42.102.0/24"]
}

variable "aws_eks_enable" {
  type    = bool
  default = false
}

variable "aws_ec2_enable" {
  type    = bool
  default = false
}

variable "tags" {
  type        = map(string)
  description = "Common AWS tags"
  default = {
    Project = "iot"
    Owner   = "allenwayne"
  }
}

# ---------------------------
# Networking / Ingress
# ---------------------------
variable "metallb_address_pool" {
  type        = list(string)
  description = "MetalLB address pool ranges"
  default     = ["192.168.50.241-192.168.50.251"]
}

variable "ingress_class" {
  type    = string
  default = "traefik"
}

# ---------------------------
# DNS / TLS
# ---------------------------
variable "external_dns_provider" {
  type        = string
  description = "Choose 'cloudflare' or 'route53'"
  default     = "cloudflare"
  validation {
    condition     = contains(["cloudflare", "route53"], lower(var.external_dns_provider))
    error_message = "external_dns_provider must be 'cloudflare' or 'route53'."
  }
}

variable "domain_name" {
  type    = string
  default = "allenwmoorejr.org"
}

variable "dns_zone_id" {
  type        = string
  description = "Cloudflare or Route53 Zone ID"
}

variable "acme_email" {
  type        = string
  description = "Let's Encrypt contact email"
}

variable "acme_env" {
  type    = string
  default = "prod" # or "staging"
}

# Cloudflare token (if using Cloudflare)
variable "cloudflare_api_token" {
  type        = string
  description = "Cloudflare API token with DNS edit on your zone"
  sensitive   = true
  default     = ""
}

# Route53 creds (if using Route53; prefer IAM/IRSA later)
variable "aws_access_key_id" {
  type        = string
  description = "AWS access key for External-DNS (Route53)"
  sensitive   = true
  default     = ""
}

variable "aws_secret_access_key" {
  type        = string
  description = "AWS secret key for External-DNS (Route53)"
  sensitive   = true
  default     = ""
}

# ---------------------------
# Registry / GitOps
# ---------------------------
variable "registry_server" {
  type    = string
  default = "index.docker.io"
}

variable "registry_username" {
  type = string
}

variable "registry_password" {
  type      = string
  sensitive = true
}

variable "gitops_repo_url" {
  type        = string
  description = "Flux/Argo source repo"
}

variable "gitops_branch" {
  type    = string
  default = "main"
}

# ---------------------------
# Observability
# ---------------------------
variable "monitoring_enable" {
  type    = bool
  default = true
}

variable "grafana_admin_user" {
  type    = string
  default = "admin"
}

variable "grafana_admin_password" {
  type      = string
  sensitive = true
}
variable "libvirt_uri" {
  type        = string
  description = "Libvirt connection URI"
  default     = "qemu:///system"
}
variable "tailscale_auth_key" {
  type        = string
  sensitive   = true
  description = "Tailscale auth key (ephemeral is best)."
}

variable "aws_instance_type" {
  type    = string
  default = "t3.micro" # free-tier-ish; t2.micro also works in many regions
}

variable "aws_ami_owner" {
  type    = string
  default = "099720109477" # Canonical (Ubuntu) owner ID
}

variable "aws_ami_name_filter" {
  type    = string
  default = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
}

variable "worker_name" {
  type    = string
  default = "k3s-cloud-worker-1"
}

variable "ssh_ingress_cidr" {
  type        = string
  default     = "0.0.0.0/0" # tighten to your /32 if you want
  description = "CIDR allowed to SSH into the worker"
}

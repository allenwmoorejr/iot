variable "aws_instance_type" {
  type    = string
  default = "t3.small"
}

variable "aws_key_name" {
  type = string
  # e.g., "allenwayne-main"
}

variable "aws_ami_owner" {
  type        = string
  default     = "099720109477" # Canonical
  description = "Owner ID for Ubuntu AMIs"
}

variable "aws_ami_name_filter" {
  type        = string
  default     = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
  description = "AMI name filter for Ubuntu 22.04"
}

variable "my_ip_cidr" {
  type        = string
  description = "Your IP for SSH, e.g. 203.0.113.10/32"
}

variable "worker_name" {
  type    = string
  default = "cloud-worker"
}

variable "k3s_url" {
  type        = string
  description = "https://<tailscale-ip-or-name>:6443"
}

variable "k3s_token" {
  type        = string
  sensitive   = true
  description = "K3s cluster token"
}

variable "tailscale_auth_key" {
  type        = string
  sensitive   = true
  description = "Tailscale auth key"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Common tags"
}
variable "aws_profile" {
  type        = string
  default     = null
  description = "AWS named profile to use (or leave null to use env/AWS SSO)."
}

variable "aws_region" {
  type        = string
  default     = "us-east-1"
  description = "AWS region."
}
variable "kubeconfig_path" {
  description = "Path to a kubeconfig file for the Kubernetes & Helm providers"
  type        = string
}

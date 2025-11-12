########################################
# Default VPC + subnets (simple path)
########################################
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "in_default_vpc" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

########################################
# Pick the first subnet (public in default VPC)
########################################
locals {
  worker_subnet_id = data.aws_subnets.in_default_vpc.ids[0]
  k3s_url_over_ts  = var.k3s_url
}

########################################
# Ubuntu 22.04 LTS AMI (Canonical)
########################################
data "aws_ami" "ubuntu_jammy" {
  most_recent = true
  owners      = [var.aws_ami_owner]

  filter {
    name   = "name"
    values = [var.aws_ami_name_filter]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

########################################
# Security group: SSH only (tighten as needed)
########################################
resource "aws_security_group" "cloud_worker_sg" {
  name        = "${var.worker_name}-sg"
  description = "SG for K3s cloud worker"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]
  }

  egress {
    description = "All egress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.worker_name}-sg" })
}

########################################
# SSH public key
########################################
resource "aws_key_pair" "main" {
  key_name   = var.aws_key_name
  public_key = file("~/.ssh/${var.aws_key_name}.pub")
}

# random for Grafana (put in some .tf file in the module)
resource "random_password" "grafana_admin" {
  length  = 24
  special = true
}

variable "grafana_admin_password" {
  type        = string
  description = "Optional override for Grafana admin password"
  default     = null
}

locals {
  effective_grafana_password = coalesce(var.grafana_admin_password, random_password.grafana_admin.result)
}

########################################
# EC2 instance: cloud worker
########################################
# cloud_worker_aws.tf
resource "aws_instance" "cloud_worker" {
  ami                         = data.aws_ami.ubuntu_jammy.id
  instance_type               = var.aws_instance_type
  subnet_id                   = local.worker_subnet_id
  key_name                    = aws_key_pair.main.key_name
  vpc_security_group_ids      = [aws_security_group.cloud_worker_sg.id]
  associate_public_ip_address = true
  # ...other args...
  user_data = templatefile("${path.module}/user_data_cloud_worker.tpl", {
    WORKER_NAME = var.worker_name
    K3S_URL     = local.k3s_url_over_ts
    K3S_TOKEN   = var.k3s_token
    TS_KEY      = var.tailscale_auth_key
  })
}

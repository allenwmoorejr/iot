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
# Pick the first subnet (they're public in default VPC)
########################################
locals {
  worker_subnet_id = data.aws_subnets.in_default_vpc.ids[0]
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
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_ingress_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.worker_name}-sg" })
}

########################################
# User data (cloud-init): Tailscale + K3s agent
########################################
locals {
  # Set k3s_url to the SERVER'S Tailscale IP, e.g., https://100.x.y.z:6443
  k3s_url_over_ts = var.k3s_url
}

resource "aws_instance" "cloud_worker" {
  ami                         = data.aws_ami.ubuntu_jammy.id
  instance_type               = var.aws_instance_type
  subnet_id                   = local.worker_subnet_id
  key_name                    = aws_key_pair.main.key_name
  vpc_security_group_ids      = [aws_security_group.cloud_worker_sg.id]
  associate_public_ip_address = true

  user_data = <<-EOF
    #cloud-config
    package_update: true
    packages:
      - curl
      - ca-certificates
    runcmd:
      - curl -fsSL https://tailscale.com/install.sh | sh
      - tailscale up --authkey=${var.tailscale_auth_key} --hostname=${var.worker_name}
      - curl -sfL https://get.k3s.io | K3S_URL=${local.k3s_url_over_ts} K3S_TOKEN='${var.k3s_token}' sh -s - agent --node-name ${var.worker_name}
  EOF

  tags = merge(var.tags, {
    Name = var.worker_name
    Role = "k3s-cloud-worker"
  })
}
# Create or register your SSH public key in AWS
resource "aws_key_pair" "main" {
  key_name   = var.aws_key_name                   # e.g., "allenwayne-main"
  public_key = file("~/.ssh/allenwayne-main.pub") # adjust path if needed
}


locals {
  aws_tags = merge(var.tags, {
    "Name" = "k3s-cloud-worker"
  })
}

data "aws_ami" "amazon_linux_2023" {
  most_recent = true

  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

resource "aws_security_group" "worker" {
  name        = "k3s-worker-sg"
  description = "Allow SSH and K3s traffic"
  vpc_id      = var.aws_vpc_id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.aws_allowed_cidr]
  }

  ingress {
    description = "K3s agent -> server"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = [var.aws_allowed_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = local.aws_tags
}

resource "aws_instance" "k3s_worker" {
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = var.aws_instance_type
  key_name                    = var.aws_key_name
  subnet_id                   = var.aws_subnet_id
  availability_zone           = var.aws_availability_zone
  associate_public_ip_address = true
  vpc_security_group_ids      = compact([aws_security_group.worker.id])

  root_block_device {
    volume_size = var.aws_root_volume_size
    volume_type = "gp3"
    encrypted   = true
  }

  user_data = templatefile("${path.module}/templates/k3s-agent.sh.tftpl", {
    k3s_url   = var.k3s_url
    k3s_token = var.k3s_token
    node_name = "k3s-cloud-worker"
  })

  metadata_options {
    http_tokens = "required"
  }

  tags = local.aws_tags
}

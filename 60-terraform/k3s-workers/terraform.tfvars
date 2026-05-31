external_dns_provider = "cloudflare" # or "route53"
domain_name           = "allenwmoorejr.org"
# Existing bits you already set:
aws_profile         = "default"
aws_region          = "us-east-1"
aws_key_name        = "allenwayne-main"
aws_vpc_cidr        = "10.42.0.0/16"
aws_public_subnets  = ["10.42.1.0/24", "10.42.2.0/24"]
aws_private_subnets = ["10.42.101.0/24", "10.42.102.0/24"]

# K3s over Tailscale:
# Install Tailscale on m1 and get its Tailscale IP (e.g., 100.87.10.5)
#k3s_url   = "https://100.87.10.5:6443"
k3s_url   = "https://100.83.32.8:6443"
k3s_token = "REVOKED-see-k3s-server-node-token"

# Tailscale (generate an ephemeral auth key in Tailscale admin)
tailscale_auth_key = "REVOKED-generate-new-key-at-admin.tailscale.com"

# Optional: restrict SSH to your public /32
ssh_ingress_cidr = "99.104.135.61/32"

# Name your worker (shows up as the node name in K3s)
worker_name = "k3s-cloud-worker-1"


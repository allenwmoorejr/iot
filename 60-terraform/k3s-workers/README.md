# K3s Worker Server Deployment

This Terraform configuration provisions two free-tier friendly worker nodes and joins them to an existing K3s control-plane:

* **Cloud worker** – AWS EC2 `t2.micro` instance (eligible for the AWS Free Tier) running Amazon Linux 2023.
* **On-prem worker** – KVM/libvirt virtual machine created on your own hardware using an Ubuntu 22.04 cloud image (free to use).

Both nodes are bootstrapped with the K3s agent and connect back to an existing K3s server using the URL and token that you supply.

> ⚠️  Nothing in this repository creates paid resources by default, but you are responsible for reviewing and adjusting the variables before you run `terraform apply` to ensure you stay within the limits of the free offerings from your cloud and on-prem environments.

## Prerequisites

1. [Terraform](https://developer.hashicorp.com/terraform/downloads) v1.5 or newer.
2. AWS credentials with permission to create EC2 instances, security groups, and key pair associations. The defaults target the free-tier `t2.micro` size in `us-east-1`.
3. A libvirt/KVM host (for example, a workstation or server running Ubuntu Server) with:
   - An Ubuntu 22.04 cloud image (`ubuntu-22.04-server-cloudimg-amd64.img`) already downloaded into a libvirt storage pool.
   - A libvirt network that can reach your K3s control-plane endpoint.
4. The K3s control-plane URL (e.g., `https://10.0.0.10:6443`) and the shared cluster token. These values are required for both workers to successfully register.
5. An SSH key pair registered in AWS and the matching public key available for the libvirt VM.

## Directory layout

```
60-terraform/k3s-workers/
├── cloud.tf
├── onprem.tf
├── outputs.tf
├── providers.tf
├── templates/
│   ├── cloud-init.yaml.tftpl
│   └── k3s-agent.sh.tftpl
└── variables.tf
```

## Usage

1. Copy `terraform.tfvars.example` (generated automatically after your first `terraform apply`) or create a new `terraform.tfvars` file with the variables shown in [`variables.tf`](./variables.tf). At a minimum you must set:
   ```hcl
   k3s_url   = "https://YOUR-CONTROL-PLANE:6443"
   k3s_token = "YOUR-SECRET"

   aws_key_name          = "your-aws-key"
   aws_allowed_cidr      = "203.0.113.0/24" # tighten from 0.0.0.0/0 when possible

   libvirt_pool          = "default"
   libvirt_network       = "default"
   libvirt_base_image    = "/var/lib/libvirt/images/ubuntu-22.04-server-cloudimg-amd64.img"
   libvirt_ssh_public_key = "ssh-ed25519 AAAA..."
   ```
2. Export credentials before running Terraform:
   ```bash
   export AWS_PROFILE=your-profile # or configure AWS_ACCESS_KEY_ID/AWS_SECRET_ACCESS_KEY
   export LIBVIRT_DEFAULT_URI=qemu:///system
   ```
3. Initialize Terraform and preview the plan:
   ```bash
   terraform init
   terraform plan
   ```
4. Apply the configuration to create both worker nodes:
   ```bash
   terraform apply
   ```
5. When you no longer need the workers, destroy them to avoid incurring usage on your AWS account and to free resources on your libvirt host:
   ```bash
   terraform destroy
   ```

## Connection details

Outputs expose connection hints for both workers. The AWS instance prints the public IP/DNS name, while the libvirt VM outputs its assigned IP address once the DHCP lease is visible to libvirt. You can SSH into either node with the same key pair used during provisioning.

## Security considerations

* Replace the default `0.0.0.0/0` SSH ingress CIDR with your own public IP range.
* Rotate the K3s token regularly and store it securely (for example, using Terraform Cloud/Enterprise or environment variables instead of committing it to disk).
* Review the generated user data scripts before applying to ensure they meet your organization's hardening standards.

## Troubleshooting

* If the libvirt VM does not receive an IP address immediately, run `virsh domifaddr <vm-name>` on the host or inspect the DHCP leases.
* Ensure that the control-plane URL is reachable from both the AWS subnet and your on-prem network. You may need to adjust firewall rules or VPN tunnels to bridge the environments.
* To use a different cloud provider, replace the resources defined in `cloud.tf` with equivalents from your provider while reusing the same K3s agent template.

## Cleaning up generated files

Terraform writes rendered cloud-init snippets into the local `rendered/` directory (ignored by Git). You can safely delete this directory after a successful destroy if you no longer need the generated files.

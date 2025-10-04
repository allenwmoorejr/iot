variable "k3s_url" {
  description = "URL of the existing K3s control-plane (for example, https://10.0.0.10:6443)."
  type        = string
}

variable "k3s_token" {
  description = "Shared K3s cluster token used to register new worker nodes."
  type        = string
  sensitive   = true
}

variable "aws_region" {
  description = "AWS region in which to provision the free-tier worker."
  type        = string
  default     = "us-east-1"
}

variable "aws_instance_type" {
  description = "Instance type for the AWS worker. Defaults to the free-tier eligible t2.micro."
  type        = string
  default     = "t2.micro"
}

variable "aws_key_name" {
  description = "Name of the existing AWS EC2 key pair to associate with the worker instance."
  type        = string
}

variable "aws_allowed_cidr" {
  description = "CIDR block allowed to SSH into the AWS worker. Replace 0.0.0.0/0 with a restricted range for production."
  type        = string
  default     = "0.0.0.0/0"
}

variable "aws_vpc_id" {
  description = "Optional VPC ID for the worker. If unset, the default VPC for the region is used."
  type        = string
  default     = null
}

variable "aws_subnet_id" {
  description = "Optional subnet ID. If null, the default subnet for the chosen availability zone is used."
  type        = string
  default     = null
}

variable "aws_availability_zone" {
  description = "Optional availability zone for the worker."
  type        = string
  default     = null
}

variable "aws_root_volume_size" {
  description = "Root volume size (GiB) for the AWS worker."
  type        = number
  default     = 20
}

variable "libvirt_uri" {
  description = "Libvirt URI of the on-prem host (for example, qemu:///system)."
  type        = string
  default     = "qemu:///system"
}

variable "libvirt_pool" {
  description = "Name of the libvirt storage pool that contains the base cloud image."
  type        = string
}

variable "libvirt_network" {
  description = "Name of the libvirt network to connect the VM to."
  type        = string
}

variable "libvirt_base_image" {
  description = "Absolute path to the Ubuntu 22.04 cloud image inside the libvirt storage pool."
  type        = string
}

variable "libvirt_disk_size" {
  description = "Disk size in GiB for the on-prem worker."
  type        = number
  default     = 20
}

variable "libvirt_memory_mb" {
  description = "RAM in MiB for the on-prem worker."
  type        = number
  default     = 2048
}

variable "libvirt_vcpu_count" {
  description = "Number of vCPUs for the on-prem worker."
  type        = number
  default     = 2
}

variable "libvirt_vm_name" {
  description = "Name to assign to the on-prem worker virtual machine."
  type        = string
  default     = "k3s-onprem-worker"
}

variable "libvirt_hostname" {
  description = "Hostname to configure inside the on-prem worker."
  type        = string
  default     = "k3s-onprem-worker"
}

variable "libvirt_ssh_public_key" {
  description = "SSH public key content injected into the on-prem worker for remote access."
  type        = string
}

variable "libvirt_network_interface" {
  description = "Name of the libvirt network interface definition to attach (defaults to using the network bridge)."
  type        = string
  default     = "default"
}

variable "libvirt_wait_for_lease" {
  description = "Whether to wait for an IP lease to become available before finishing apply."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Map of tags/labels applied to both workers."
  type        = map(string)
  default = {
    "Project" = "hb-suite"
    "Role"    = "k3s-worker"
  }
}

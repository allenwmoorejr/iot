variable "ssh_ingress_cidr" {
  type        = string
  default     = "" # leave empty to auto-detect
  description = "CIDR allowed to SSH; leave blank to use your current public /32"
}

data "http" "myip" {
  url = "https://api.ipify.org"
}

locals {
  my_ip_cidr = "${chomp(data.http.myip.response_body)}/32"
  ssh_cidr   = var.ssh_ingress_cidr != "" ? var.ssh_ingress_cidr : local.my_ip_cidr
}


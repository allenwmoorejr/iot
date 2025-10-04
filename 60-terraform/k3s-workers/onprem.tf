locals {
  libvirt_tags = merge(var.tags, {
    "Name" = var.libvirt_vm_name
  })

  rendered_dir           = "${path.module}/rendered"
  onprem_cloud_init_name = "${var.libvirt_vm_name}-cloud-init.yaml"
  onprem_cloud_init_path = "${local.rendered_dir}/${local.onprem_cloud_init_name}"
}

resource "null_resource" "rendered_dir" {
  triggers = {
    path = local.rendered_dir
  }

  provisioner "local-exec" {
    command = "mkdir -p ${local.rendered_dir}"
  }
}

resource "local_file" "cloud_init" {
  depends_on = [null_resource.rendered_dir]

  filename = local.onprem_cloud_init_path
  content  = templatefile("${path.module}/templates/cloud-init.yaml.tftpl", {
    hostname  = var.libvirt_hostname
    ssh_key   = var.libvirt_ssh_public_key
    k3s_url   = var.k3s_url
    k3s_token = var.k3s_token
    node_name = var.libvirt_hostname
  })
}

resource "libvirt_volume" "worker_disk" {
  name   = "${var.libvirt_vm_name}.qcow2"
  pool   = var.libvirt_pool
  source = var.libvirt_base_image
  format = "qcow2"
  size   = var.libvirt_disk_size * 1024 * 1024 * 1024
}

resource "libvirt_cloudinit_disk" "cloudinit" {
  name      = "${var.libvirt_vm_name}-cloudinit.iso"
  pool      = var.libvirt_pool
  user_data = local_file.cloud_init.content
  meta_data = <<EOT
{
  "instance-id": "${var.libvirt_vm_name}",
  "local-hostname": "${var.libvirt_hostname}"
}
EOT
}

resource "libvirt_domain" "worker" {
  name   = var.libvirt_vm_name
  memory = var.libvirt_memory_mb
  vcpu   = var.libvirt_vcpu_count

  cpu {
    mode = "host-passthrough"
  }

  cloudinit = libvirt_cloudinit_disk.cloudinit.id

  network_interface {
    network_name   = var.libvirt_network
    wait_for_lease = var.libvirt_wait_for_lease
  }

  disk {
    volume_id = libvirt_volume.worker_disk.id
  }

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }

  console {
    type        = "pty"
    target_type = "serial"
    target_port = "0"
  }
}

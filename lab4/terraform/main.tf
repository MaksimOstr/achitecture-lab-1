locals {
  ansible_public_key  = trimspace(file(pathexpand(var.ssh_public_key_path)))
  ansible_private_key = pathexpand(var.ssh_private_key_path)
  worker_ip          = libvirt_domain.worker.network_interface[0].addresses[0]
  db_ip              = libvirt_domain.db.network_interface[0].addresses[0]
}

resource "libvirt_network" "lab" {
  name      = "${var.project_name}-net"
  mode      = "nat"
  addresses = [var.network_cidr]

  dns {
    enabled = true
  }
}

resource "libvirt_volume" "worker_disk" {
  name   = "${var.project_name}-worker.qcow2"
  source = pathexpand(var.ubuntu_cloud_image_path)
  format = "qcow2"
}

resource "libvirt_volume" "worker_disk_resized" {
  name           = "${var.project_name}-worker-resized.qcow2"
  base_volume_id = libvirt_volume.worker_disk.id
  size           = var.worker_disk_bytes
}

resource "libvirt_volume" "db_disk" {
  name   = "${var.project_name}-db.qcow2"
  source = pathexpand(var.ubuntu_cloud_image_path)
  format = "qcow2"
}

resource "libvirt_volume" "db_disk_resized" {
  name           = "${var.project_name}-db-resized.qcow2"
  base_volume_id = libvirt_volume.db_disk.id
  size           = var.db_disk_bytes
}

resource "libvirt_cloudinit_disk" "worker" {
  name      = "${var.project_name}-worker-cloudinit.iso"
  user_data = templatefile("${path.module}/cloud-init.yaml.tftpl", {
    hostname               = "worker"
    ansible_ssh_public_key = local.ansible_public_key
  })
}

resource "libvirt_cloudinit_disk" "db" {
  name      = "${var.project_name}-db-cloudinit.iso"
  user_data = templatefile("${path.module}/cloud-init.yaml.tftpl", {
    hostname               = "db"
    ansible_ssh_public_key = local.ansible_public_key
  })
}

resource "libvirt_domain" "worker" {
  name      = "${var.project_name}-worker"
  memory    = var.worker_memory_mb
  vcpu      = var.worker_vcpu
  cloudinit = libvirt_cloudinit_disk.worker.id

  disk {
    volume_id = libvirt_volume.worker_disk_resized.id
  }

  network_interface {
    network_id     = libvirt_network.lab.id
    hostname       = "worker"
    wait_for_lease = true
  }

  console {
    type        = "pty"
    target_type = "serial"
    target_port = "0"
  }
}

resource "libvirt_domain" "db" {
  name      = "${var.project_name}-db"
  memory    = var.db_memory_mb
  vcpu      = var.db_vcpu
  cloudinit = libvirt_cloudinit_disk.db.id

  disk {
    volume_id = libvirt_volume.db_disk_resized.id
  }

  network_interface {
    network_id     = libvirt_network.lab.id
    hostname       = "db"
    wait_for_lease = true
  }

  console {
    type        = "pty"
    target_type = "serial"
    target_port = "0"
  }
}

resource "local_file" "ansible_inventory" {
  filename = "${path.module}/../ansible/inventory/hosts.ini"
  content = templatefile("${path.module}/inventory.ini.tftpl", {
    worker_ip            = local.worker_ip
    db_ip                = local.db_ip
    ssh_private_key_path = local.ansible_private_key
  })
}

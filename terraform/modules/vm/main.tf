resource "proxmox_vm_qemu" "vm" {
  name        = var.vm_name
  vmid        = var.vm_id
  target_node = var.proxmox_node
  clone       = var.template
  full_clone  = true

  cores   = var.cores
  sockets = 1
  memory  = var.memory
  agent   = 1

  os_type  = "cloud-init"
  ciuser   = "ubuntu"
  sshkeys  = var.ssh_public_key
  ipconfig0 = "ip=${var.ip_address},gw=${var.gateway}"
  nameserver = var.dns

  disk {
    slot    = 0
    size    = var.disk_size
    type    = "scsi"
    storage = var.storage
    iothread = true
  }

  network {
    model  = "virtio"
    bridge = "vmbr0"
  }

  tags = join(",", var.tags)

  lifecycle {
    ignore_changes = [network]
  }
}

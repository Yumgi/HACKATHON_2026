# Bareos — Ubuntu 22.04 — VLAN 20 SERVERS
# Le dépôt officiel download.bareos.org cible explicitement xUbuntu_22.04.
# Disque large (100G) : stockage des dumps PostgreSQL et données applicatives.

resource "proxmox_lxc" "bareos" {
  target_node  = var.proxmox_node
  vmid         = 107
  hostname     = "bareos"
  ostemplate   = var.tpl_ubuntu2204
  unprivileged = true

  cores  = 2
  memory = 2048
  swap   = 512

  ssh_public_keys = var.ssh_public_key
  tags            = "acme;vlan20;backup;ubuntu2204"
  start           = true
  onboot          = true

  rootfs {
    storage = var.storage_pool
    size    = "100G"
  }

  network {
    name   = "eth0"
    bridge = var.servers_bridge
    ip     = "10.20.0.50/24"
    gw     = var.servers_gateway
  }

  features {
    nesting = false
    keyctl  = false
  }

  nameserver = "10.20.0.10"

  depends_on = [proxmox_lxc.postgresql]
}

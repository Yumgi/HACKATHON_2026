# Loki + Promtail — Debian 12 — VLAN 20 SERVERS
# Binaires Go statiques, aucune dépendance distro-specific.

resource "proxmox_lxc" "loki" {
  target_node  = var.proxmox_node
  vmid         = 106
  hostname     = "loki"
  ostemplate   = var.tpl_debian12
  unprivileged = true

  cores  = 2
  memory = 2048
  swap   = 512

  ssh_public_keys = var.ssh_public_key
  tags            = "acme;vlan20;logging;debian12"
  start           = true
  onboot          = true

  rootfs {
    storage = var.storage_pool
    size    = "30G"
  }

  network {
    name   = "eth0"
    bridge = var.servers_bridge
    ip     = "10.20.0.42/24"
    gw     = var.servers_gateway
  }

  features {
    nesting = false
    keyctl  = false
  }

  nameserver = "10.20.0.10"
}

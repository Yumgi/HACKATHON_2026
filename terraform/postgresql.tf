# PostgreSQL — Debian 12 — VLAN 20 SERVERS
# Dépôt PGDG officiel stable sur Debian.
# Empreinte mémoire minimale, pas de services superflus.

resource "proxmox_lxc" "postgresql" {
  target_node  = var.proxmox_node
  vmid         = 102
  hostname     = "pg"
  ostemplate   = var.tpl_debian12
  unprivileged = true

  cores  = 2
  memory = 4096
  swap   = 1024

  ssh_public_keys = var.ssh_public_key
  tags            = "acme;vlan20;database;debian12"
  start           = true
  onboot          = true

  rootfs {
    storage = var.storage_pool
    size    = "50G"
  }

  network {
    name   = "eth0"
    bridge = var.servers_bridge
    ip     = "10.20.0.20/24"
    gw     = var.servers_gateway
  }

  features {
    nesting = false
    keyctl  = false
  }

  nameserver = "10.20.0.10"

  depends_on = [proxmox_lxc.freeipa]
}

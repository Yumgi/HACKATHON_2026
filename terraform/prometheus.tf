# Prometheus + Alertmanager — Debian 12 — VLAN 20 SERVERS
# Binaires statiques Go, aucune dépendance distro-specific.

resource "proxmox_lxc" "prometheus" {
  target_node  = var.proxmox_node
  vmid         = 104
  hostname     = "prometheus"
  ostemplate   = var.tpl_debian12
  unprivileged = true

  cores  = 2
  memory = 2048
  swap   = 512

  ssh_public_keys = var.ssh_public_key
  tags            = "acme;vlan20;monitoring;debian12"
  start           = true
  onboot          = true

  rootfs {
    storage = var.storage_pool
    size    = "30G"
  }

  network {
    name   = "eth0"
    bridge = var.servers_bridge
    ip     = "10.20.0.40/24"
    gw     = var.servers_gateway
  }

  features {
    nesting = false
    keyctl  = false
  }

  initialization {
    hostname = "prometheus.${var.domain}"
    dns {
      server = "10.20.0.10"
    }
  }
}

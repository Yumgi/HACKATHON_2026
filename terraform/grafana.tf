# Grafana — Ubuntu 22.04 — VLAN 20 SERVERS
# Dépôt APT officiel grafana.com cible Ubuntu 22.04 LTS.

resource "proxmox_lxc" "grafana" {
  target_node  = var.proxmox_node
  vmid         = 105
  hostname     = "grafana"
  ostemplate   = var.tpl_ubuntu2204
  unprivileged = true

  cores  = 2
  memory = 2048
  swap   = 512

  ssh_public_keys = var.ssh_public_key
  tags            = "acme;vlan20;monitoring;ubuntu2204"
  start           = true
  onboot          = true

  rootfs {
    storage = var.storage_pool
    size    = "20G"
  }

  network {
    name   = "eth0"
    bridge = var.servers_bridge
    ip     = "10.20.0.41/24"
    gw     = var.servers_gateway
  }

  features {
    nesting = false
    keyctl  = false
  }

  nameserver = "10.20.0.10"

  depends_on = [proxmox_lxc.prometheus]
}

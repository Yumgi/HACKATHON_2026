# GLPI — Ubuntu 22.04 — VLAN 20 SERVERS
# Application ITSM open-source : ticketing, gestion des actifs, LDAP natif.
# Ubuntu 22.04 : PHP 8.1 disponible via apt, Apache2, support officiel GLPI.
# Accès via Traefik (DMZ → SERVERS autorisé par pfSense sur :80).

resource "proxmox_lxc" "glpi" {
  target_node  = var.proxmox_node
  vmid         = 103
  hostname     = "glpi"
  ostemplate   = var.tpl_ubuntu2204
  unprivileged = true

  cores  = 2
  memory = 2048
  swap   = 512

  ssh_public_keys = var.ssh_public_key
  tags            = "acme;vlan20;app;ubuntu2204"
  start           = true
  onboot          = true

  rootfs {
    storage = var.storage_pool
    size    = "20G"
  }

  network {
    name   = "eth0"
    bridge = var.servers_bridge
    ip     = "10.20.0.30/24"
    gw     = var.servers_gateway
  }

  features {
    nesting = false
    keyctl  = false
  }

  initialization {
    hostname = "glpi.${var.domain}"
    dns {
      server = "10.20.0.10"
    }
  }

  depends_on = [proxmox_lxc.freeipa, proxmox_lxc.postgresql]
}

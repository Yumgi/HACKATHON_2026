# Traefik — Debian 12 — VLAN 30 DMZ
# Reverse proxy HTTPS, point d'entrée unique depuis WAN et LAN.
# Termine le TLS (Certbot/Let's Encrypt) et proxifie vers GLPI (SERVERS).
# nesting=true + keyctl=true : Docker overlay2 dans LXC non privilégié.

resource "proxmox_lxc" "traefik" {
  target_node  = var.proxmox_node
  vmid         = 201
  hostname     = "traefik"
  ostemplate   = var.tpl_debian12
  unprivileged = true

  cores  = 2
  memory = 2048
  swap   = 512

  ssh_public_keys = var.ssh_public_key
  tags            = "acme;vlan30;proxy;debian12"
  start           = true
  onboot          = true

  rootfs {
    storage = var.storage_pool
    size    = "20G"
  }

  network {
    name   = "eth0"
    bridge = var.dmz_bridge
    ip     = "10.30.0.10/24"
    gw     = var.dmz_gateway
  }

  features {
    nesting = true   # Docker-in-LXC
    keyctl  = true   # overlay2 filesystem
  }

  initialization {
    hostname = "traefik.${var.domain}"
    dns {
      server = "10.20.0.10"
    }
  }
}

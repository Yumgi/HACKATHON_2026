# FreeIPA — Rocky Linux 9 — VLAN 20 SERVERS
# RHEL-based : seul OS officiellement supporté par FreeIPA upstream.
# Conteneur PRIVILÉGIÉ (unprivileged=false) : systemd-journald, 389-ds
# et Kerberos exigent l'accès complet à /proc et aux cgroups.

resource "proxmox_lxc" "freeipa" {
  target_node  = var.proxmox_node
  vmid         = 101
  hostname     = "ipa"
  ostemplate   = var.tpl_rhel9
  unprivileged = false

  cores  = 2
  memory = 4096
  swap   = 512

  ssh_public_keys = var.ssh_public_key
  tags            = "acme;vlan20;identity;rhel9"
  start           = true
  onboot          = true

  rootfs {
    storage = var.storage_pool
    size    = "30G"
  }

  network {
    name   = "eth0"
    bridge = var.servers_bridge
    ip     = "10.20.0.10/24"
    gw     = var.servers_gateway
  }

  features {
    nesting = true   # systemd dans le container
    keyctl  = false
  }

  nameserver = "10.20.0.10"
}

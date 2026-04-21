# Ce module documente les bridges réseau Proxmox.
# Les bridges sont créés manuellement sur Proxmox ou via l'API Proxmox.
# vmbr0 = LAN_USERS (192.168.1.0/24)
# vmbr1 = SERVERS   (192.168.10.0/24)
# vmbr2 = DMZ       (192.168.20.0/24)

variable "proxmox_node" { type = string }

output "bridges" {
  value = {
    lan_users = "vmbr0 — 192.168.1.0/24"
    servers   = "vmbr1 — 192.168.10.0/24"
    dmz       = "vmbr2 — 192.168.20.0/24"
  }
}

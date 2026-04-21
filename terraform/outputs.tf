output "containers" {
  description = "Récapitulatif des containers LXC provisionnés"
  value = {
    # VLAN 20 — SERVERS
    freeipa    = { vmid = proxmox_lxc.freeipa.vmid,    ip = "10.20.0.10", os = "Rocky Linux 9",  vlan = 20 }
    postgresql = { vmid = proxmox_lxc.postgresql.vmid, ip = "10.20.0.20", os = "Debian 12",      vlan = 20 }
prometheus = { vmid = proxmox_lxc.prometheus.vmid, ip = "10.20.0.40", os = "Debian 12",      vlan = 20 }
    grafana    = { vmid = proxmox_lxc.grafana.vmid,    ip = "10.20.0.41", os = "Ubuntu 22.04",   vlan = 20 }
    loki       = { vmid = proxmox_lxc.loki.vmid,       ip = "10.20.0.42", os = "Debian 12",      vlan = 20 }
    bareos     = { vmid = proxmox_lxc.bareos.vmid,     ip = "10.20.0.50", os = "Ubuntu 22.04",   vlan = 20 }
    # VLAN 30 — DMZ
    traefik    = { vmid = proxmox_lxc.traefik.vmid,    ip = "10.30.0.10", os = "Debian 12",      vlan = 30 }
  }
}

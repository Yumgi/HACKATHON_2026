variable "proxmox_api_url" {
  description = "URL de l'API Proxmox (ex: https://10.229.0.2:8006/api2/json)"
  type        = string
  default     = "https://10.229.0.2:8006/api2/json"
}

variable "proxmox_user" {
  description = "Utilisateur Proxmox avec realm (ex: root@pam ou user@LAB)"
  type        = string
  default     = "s.lefebvre@LAB-LYON"
}

variable "proxmox_password" {
  description = "Mot de passe Proxmox"
  type        = string
  sensitive   = true
}

variable "proxmox_node" {
  description = "Nom du nœud Proxmox cible"
  type        = string
  default     = "proxmox-02"
}

variable "storage_pool" {
  description = "Pool de stockage pour les rootfs LXC"
  type        = string
  default     = "local-lvm"
}

variable "ssh_public_key" {
  description = "Clé publique SSH injectée dans les containers"
  type        = string
}

variable "domain" {
  description = "Domaine interne ACME"
  type        = string
  default     = "acme.local"
}

# ─── VLAN 20 — SERVERS (bridge: vmbr2) ───────────────────────────────────────

variable "servers_bridge" {
  description = "Bridge Proxmox VLAN 20 — SERVERS"
  type        = string
  default     = "vmbr2"
}

variable "servers_gateway" {
  description = "Passerelle VLAN 20 — pfSense interface SERVERS"
  type        = string
  default     = "10.20.0.1"
}

# ─── VLAN 30 — DMZ (bridge: vmbr3) ───────────────────────────────────────────

variable "dmz_bridge" {
  description = "Bridge Proxmox VLAN 30 — DMZ"
  type        = string
  default     = "vmbr3"
}

variable "dmz_gateway" {
  description = "Passerelle VLAN 30 — pfSense interface DMZ"
  type        = string
  default     = "10.30.0.1"
}

# ─── Templates LXC disponibles sur Proxmox ────────────────────────────────────
# Vérifier les noms exacts avec : pveam list local

variable "tpl_rhel9" {
  description = "Template Rocky Linux 9 (RHEL — FreeIPA)"
  type        = string
  default     = "ISO:vztmpl/rockylinux-9-default_20240912_amd64.tar.xz"
}

variable "tpl_ubuntu2204" {
  description = "Template Ubuntu 22.04 (Grafana, Bareos)"
  type        = string
  default     = "ISO:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst"
}

variable "tpl_debian12" {
  description = "Template Debian 12 (Prometheus, Loki, Traefik)"
  type        = string
  default     = "ISO:vztmpl/debian-12-standard_12.12-1_amd64.tar.zst"
}
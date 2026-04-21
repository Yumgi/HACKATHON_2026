variable "proxmox_api_url" {
  description = "URL de l'API Proxmox (ex: https://proxmox.acme.local:8006/api2/json)"
  type        = string
}

variable "proxmox_user" {
  description = "Utilisateur Proxmox"
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
  default     = "pve"
}

variable "proxmox_template" {
  description = "Nom du template cloud-init à cloner"
  type        = string
  default     = "ubuntu-22.04-cloud"
}

variable "ssh_public_key" {
  description = "Clé publique SSH injectée via cloud-init"
  type        = string
}

variable "domain" {
  description = "Domaine interne ACME"
  type        = string
  default     = "acme.local"
}

variable "dns_server" {
  description = "Serveur DNS interne (FreeIPA)"
  type        = string
  default     = "192.168.10.10"
}

variable "network_gateway_servers" {
  type    = string
  default = "10.10.0.1 "
}

variable "network_gateway_dmz" {
  type    = string
  default = "192.168.20.1"
}

variable "storage_pool" {
  description = "Pool de stockage Proxmox"
  type        = string
  default     = "local-lvm"
}

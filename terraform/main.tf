terraform {
  required_version = ">= 1.6"

  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "~> 2.9"
    }
  }
}

provider "proxmox" {
  pm_api_url      = var.proxmox_api_url
  pm_user         = var.proxmox_user
  pm_password     = var.proxmox_password
  pm_tls_insecure = true
}

# ─── Réseau ──────────────────────────────────────────────────────────────────

module "network" {
  source      = "./modules/network"
  proxmox_node = var.proxmox_node
}

# ─── FreeIPA ─────────────────────────────────────────────────────────────────

module "freeipa" {
  source           = "./modules/vm"
  vm_name          = "acme-freeipa"
  vm_id            = 101
  proxmox_node     = var.proxmox_node
  template         = var.proxmox_template
  cores            = 2
  memory           = 4096
  disk_size        = "30G"
  storage          = var.storage_pool
  ip_address       = "192.168.10.10/24"
  gateway          = var.network_gateway_servers
  dns              = "1.1.1.1"  # bootstrap avant FreeIPA
  ssh_public_key   = var.ssh_public_key
  tags             = ["acme", "servers", "identity"]

  depends_on = [module.network]
}

# ─── PostgreSQL ───────────────────────────────────────────────────────────────

module "postgresql" {
  source           = "./modules/vm"
  vm_name          = "acme-postgres"
  vm_id            = 102
  proxmox_node     = var.proxmox_node
  template         = var.proxmox_template
  cores            = 2
  memory           = 4096
  disk_size        = "50G"
  storage          = var.storage_pool
  ip_address       = "192.168.10.20/24"
  gateway          = var.network_gateway_servers
  dns              = var.dns_server
  ssh_public_key   = var.ssh_public_key
  tags             = ["acme", "servers", "database"]

  depends_on = [module.freeipa]
}

# ─── Monitoring (Prometheus + Grafana) ────────────────────────────────────────

module "monitoring" {
  source           = "./modules/vm"
  vm_name          = "acme-monitoring"
  vm_id            = 103
  proxmox_node     = var.proxmox_node
  template         = var.proxmox_template
  cores            = 2
  memory           = 4096
  disk_size        = "40G"
  storage          = var.storage_pool
  ip_address       = "192.168.10.30/24"
  gateway          = var.network_gateway_servers
  dns              = var.dns_server
  ssh_public_key   = var.ssh_public_key
  tags             = ["acme", "servers", "monitoring"]

  depends_on = [module.network]
}

# ─── Loki ────────────────────────────────────────────────────────────────────

module "loki" {
  source           = "./modules/vm"
  vm_name          = "acme-loki"
  vm_id            = 104
  proxmox_node     = var.proxmox_node
  template         = var.proxmox_template
  cores            = 2
  memory           = 2048
  disk_size        = "30G"
  storage          = var.storage_pool
  ip_address       = "192.168.10.40/24"
  gateway          = var.network_gateway_servers
  dns              = var.dns_server
  ssh_public_key   = var.ssh_public_key
  tags             = ["acme", "servers", "logging"]

  depends_on = [module.network]
}

# ─── Bareos ───────────────────────────────────────────────────────────────────

module "bareos" {
  source           = "./modules/vm"
  vm_name          = "acme-bareos"
  vm_id            = 105
  proxmox_node     = var.proxmox_node
  template         = var.proxmox_template
  cores            = 2
  memory           = 2048
  disk_size        = "100G"
  storage          = var.storage_pool
  ip_address       = "192.168.10.50/24"
  gateway          = var.network_gateway_servers
  dns              = var.dns_server
  ssh_public_key   = var.ssh_public_key
  tags             = ["acme", "servers", "backup"]

  depends_on = [module.network]
}

# ─── Traefik (DMZ) ────────────────────────────────────────────────────────────

module "traefik" {
  source           = "./modules/vm"
  vm_name          = "acme-traefik"
  vm_id            = 201
  proxmox_node     = var.proxmox_node
  template         = var.proxmox_template
  cores            = 2
  memory           = 2048
  disk_size        = "20G"
  storage          = var.storage_pool
  ip_address       = "192.168.20.10/24"
  gateway          = var.network_gateway_dmz
  dns              = var.dns_server
  ssh_public_key   = var.ssh_public_key
  tags             = ["acme", "dmz", "proxy"]

  depends_on = [module.network]
}

# ─── Application Flask (DMZ) ──────────────────────────────────────────────────

module "app" {
  source           = "./modules/vm"
  vm_name          = "acme-app"
  vm_id            = 202
  proxmox_node     = var.proxmox_node
  template         = var.proxmox_template
  cores            = 2
  memory           = 2048
  disk_size        = "20G"
  storage          = var.storage_pool
  ip_address       = "192.168.20.20/24"
  gateway          = var.network_gateway_dmz
  dns              = var.dns_server
  ssh_public_key   = var.ssh_public_key
  tags             = ["acme", "dmz", "app"]

  depends_on = [module.freeipa, module.postgresql]
}

output "freeipa_ip" {
  value = "192.168.10.10"
}

output "postgresql_ip" {
  value = "192.168.10.20"
}

output "monitoring_ip" {
  value = "192.168.10.30"
}

output "loki_ip" {
  value = "192.168.10.40"
}

output "bareos_ip" {
  value = "192.168.10.50"
}

output "traefik_ip" {
  value = "192.168.20.10"
}

output "app_ip" {
  value = "192.168.20.20"
}

output "ansible_inventory_hint" {
  value = <<-EOT
    Copier dans ansible/inventory/hosts.yml :
      freeipa    : 192.168.10.10
      postgresql : 192.168.10.20
      monitoring : 192.168.10.30
      loki       : 192.168.10.40
      bareos     : 192.168.10.50
      traefik    : 192.168.20.10
      app        : 192.168.20.20
  EOT
}
